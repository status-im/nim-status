import # chat libs
  ./screen, ./tasks

export screen, tasks

logScope:
  topics = "chat"

type
  Command* = ref object of RootObj
  Login* = ref object of Command
  Logout* = ref object of Command
  SendMessage* = ref object of Command
    message*: string

const commands*: seq[string] = @[
  "Login",
  "Logout",
  "SendMessage"
]

proc new*(T: type SendMessage, args: varargs[string]): T =
  T(message: args[0])

proc command*(self: ChatTUI, command: SendMessage) {.async, gcsafe, nimcall.} =
  let message = command.message

  trace "TUI requested client send message", message
  # ... self.client.send(message) ...

proc parse*(command: string): (string, seq[string], bool) =
  var
    args: seq[string] = @[]
    cmd = "" # if set should be name of type that derives from Command
    isCmd = false

  # ... decompose command string into cmd and args ...
  # idea: use a table that pairs e.g. "login" to "Login", etc.
  # `cmd` can be the `[0]` index of the command string split on " " (but
  # left-trimmed before split, though message text shouldn't be trimmed so only
  # do it here)

  # actually may not want to use `split` from strutils and instead after
  # left-trim find the first " "; the part of the string before the first " "
  # is assigned to `cmd`, though also need to consider case where " " is not
  # found so the whole string is `cmd`

  if isCmd: (cmd, args, true) else: ("", @[], false)
