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

proc command*(self: ChatTUI, command: SendMessage) {.async, gcsafe, nimcall.} =
  let message = command.message

  trace "TUI requested client send message", message
  # ... self.client.send(message) ...
