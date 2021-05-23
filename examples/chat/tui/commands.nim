import # std libs
  strutils

import # chat libs
  ./macros, ./screen, ./tasks

export macros, screen, strutils, tasks

logScope:
  topics = "chat"

# workaround for a problem (compiler bug?) affecting exported tables; if this is
# not done the compiler will fail with error `undeclared identifier: 'hasKey'`
const
  aliased = macros.common.aliased
  aliases = macros.common.aliases
  commands = macros.common.commands

# Command types are defined in ./common to avoid a circular dependency because
# multiple modules in this directory make use of them

# `split` procs for command args should only be concerned about splitting the
# raw string appropriately and avoid validation logic beyond bare minimum to
# generate the correct number of members in the returned `seq[string]`

# `command` procs should be reponsible for validation and execution with
# respect to fields on the instantiated types derived from Command; authoring
# `split` and `command` and type definitions that derive from Command (as well
# their respective `new` procs) will involve consideration of special strings
# (e.g. empty string) that a `split` proc populates into its returned
# `seq[string]` indicating e.g. a special value or missing arg or some other
# problem or special case that `split` ran into, and the correpsonding
# `command` proc should implement the appropriate logic to deal with those
# values

# Help -------------------------------------------------------------------------

proc new*(T: type Help, args: varargs[string]): T =
  T(command: args[0])

proc split*(T: type Help, argsRaw: string): seq[string] =
  @[argsRaw.split(" ")[0]]

proc command*(self: ChatTUI, command: Help) {.async, gcsafe, nimcall.} =
  let command = command.command
  trace "TUI requested help", command

# Login ------------------------------------------------------------------------

proc new*(T: type Login, args: varargs[string]): T {.raises: [].} =
  T(username: args[0], password: args[1])

proc split*(T: type Login, argsRaw: string): seq[string] =
  # don't really want to split on space because password could contain spaces
  # though username would not; also need to consider missing 1 or 2 args
  argsRaw.split(" ")

proc command*(self: ChatTUI, command: Login) {.async, gcsafe, nimcall.} =
  let
    username = command.username
    password = command.password

  trace "TUI requested client login", username, password="***"

# Logout -----------------------------------------------------------------------

proc new*(T: type Logout, args: varargs[string]): T =
  T()

proc split*(T: type Logout, argsRaw: string): seq[string] =
  return @[]

proc command*(self: ChatTUI, command: Logout) {.async, gcsafe, nimcall.} =
  trace "TUI requested client logout"

# SendMessage ------------------------------------------------------------------

proc new*(T: type SendMessage, args: varargs[string]): T =
  T(message: args[0])

proc split*(T: type SendMessage, argsRaw: string): seq[string] =
  @[argsRaw]

proc command*(self: ChatTUI, command: SendMessage) {.async, gcsafe, nimcall.} =
  let message = command.message
  trace "TUI requested client send message", message
  # ... self.client.send(message) ...

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
      argsRaw = commandRaw
      isCommand = true

    elif stripped.strip() != "/" and
         stripped.len >= 2 and
         stripped[1..^1].strip(trailing = false) == stripped[1..^1]:
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
    commandSplitCases()
    (command, args, true)
  else:
    ("", @[], false)
