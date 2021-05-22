import # std libs
  strutils

import # chat libs
  ./screen, ./tasks

export screen, strutils, tasks

logScope:
  topics = "chat"

type
  Command* = ref object of RootObj
  # all fields on types that derive from Command should be of type `string`
  Help* = ref object of Command
    command*: string
  Login* = ref object of Command
    username*: string
    password*: string
  Logout* = ref object of Command
  SendMessage* = ref object of Command
    message*: string

const DEFAULT_COMMAND* = ""

const
  commands* = {
    DEFAULT_COMMAND: "SendMessage",
    "help": "Help",
    "login": "Login",
    "logout": "Logout"
  }.toTable

  aliases* = {
    "?": "help"
  }.toTable

  aliased* = {
    "help": ["?"]
  }

# `parse` procs for command args should only be concerned about splitting the
# string appropriately and avoid validation logic beyond bare minimum to
# generate the correct number of members in the returned `seq[string]`

# `command` procs should be reponsible for final validation and execution with
# respect to fields on the instantiated types derived from Command; authoring
# `parse` and `command` and type definitions that derive from Command (as well
# their respective `new` procs) will involve consideration of special strings
# that a `parse` proc populates into its returned `seq[string]` indicating
# e.g. a special value or missing arg or some other problem or special case
# that `parse` ran into, and the correpsonding `command` proc should implement
# the appropriate logic to deal with those values e.g. printing an
# error/explanation to the output window

# Help -------------------------------------------------------------------------

proc new*(T: type Help, args: varargs[string]): T =
  T(command: args[0])

proc parse*(T: type Help, args: string): seq[string] =
  @[args.split(" ")[0]]

proc command*(self: ChatTUI, command: Help) {.async, gcsafe, nimcall.} =
  let command = command.command

  trace "TUI requested help", command

# SendMessage ------------------------------------------------------------------

# should probably use tuples with named members instead o varargs and in the `case..of` in actions dispatch for commands shoul generate code for not only the new call but also the parse call
proc new*(T: type SendMessage, args: varargs[string]): T =
  T(message: args[0])

proc parse*(T: type SendMessage, args: string): seq[string] =
  @[args]

proc command*(self: ChatTUI, command: SendMessage) {.async, gcsafe, nimcall.} =
  let message = command.message

  trace "TUI requested client send message", message
  # ... self.client.send(message) ...

# Login ------------------------------------------------------------------------

proc new*(T: type Login, args: varargs[string]): T {.raises: [].} =
  T(username: args[0], password: args[1])

proc parse*(T: type Login, args: string): seq[string] =
  # don't really want to split on space because password could contain spaces
  # though username would not; also need to consider missing 1 or 2 args
  args.split(" ")

proc command*(self: ChatTUI, command: Login) {.async, gcsafe, nimcall.} =
  let
    username = command.username
    password = command.password

  trace "TUI requested client login", username, password="***"

# Logout -----------------------------------------------------------------------

proc new*(T: type Logout, args: varargs[string]): T =
  T()

proc parse*(T: type Logout, args: string): seq[string] =
  return @[]

proc command*(self: ChatTUI, command: Logout) {.async, gcsafe, nimcall.} =
  trace "TUI requested client logout"

# ------------------------------------------------------------------------------

proc parse*(commandRaw: string): (string, seq[string], bool) =
  var
    args: seq[string]
    argsRaw: string
    command: string
    isCommand = false
    stripped = commandRaw.strip(trailing = false)

  if stripped != "" :
    if stripped[0] != '/':
      command = commands[DEFAULT_COMMAND]
      argsRaw = command
      isCommand = true

    elif stripped.strip() != "/" and
         stripped.len >= 2 and
         stripped[1..^1].strip(trailing = false) ==
           stripped[1..^1]:
      let firstSpace = stripped.find(" ")
      var maybeCommand: string

      if firstSpace == -1:
        maybeCommand = stripped[1..^1]
      else:
        maybeCommand = stripped[1..<firstSpace]
        let argsStart = firstSpace + 1

        if stripped.len == argsStart:
          argsRaw = ""
        else:
          argsRaw = stripped[argsStart..^1]

      if aliases.hasKey(maybeCommand):
        maybeCommand = aliases[maybeCommand]

      if commands.hasKey(maybeCommand):
        command = commands[maybeCommand]
        isCommand = true

  if isCommand:
    # should be able to gen the following code with a template
    case command:
      # of ...:

      of "Help":
        args = Help.parse(argsRaw)

      of "Login":
        args = Login.parse(argsRaw)

      of "Logout":
        args = Login.parse(argsRaw)

      of "SendMessage":
        args = SendMessage.parse(argsRaw)

    (command, args, true)

  else:
    ("", @[], false)
