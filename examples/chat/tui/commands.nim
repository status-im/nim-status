import # chat libs
  ./screen, ./tasks

export screen, tasks

logScope:
  topics = "chat"

type
  Command* = proc(self: ChatTUI, cmd: CommandEvent): Future[void] {.gcsafe, nimcall.}
  CommandEvent* = ref object of Event
  Login* = ref object of CommandEvent
  Logout* = ref object of CommandEvent
  SendMessage* = ref object of CommandEvent
    message*: string

const sendMessage*: Command = proc(self: ChatTUI, cmd: CommandEvent) {.async, gcsafe, nimcall.} =
  let
    cmd = cast[SendMessage](cmd)
    message = cmd.message

  trace "TUI requested client send message", message

  # ... self.client.send(input) ...


proc dispatchCommand*(self: ChatTUI, command: string) {.gcsafe, nimcall.} =
  let
    args: seq[string] = @[]
    cmd = ""

    # match and/or decompose command string into command and arguments

  case cmd:
    # need cases for commands, but first may want to check against an
    # "available commands set" that will vary depending on the state of the
    # TUI, e.g. if already logged in or login is in progress, then login
    # command shouldn't be available but logout command should be available

    # of ...:

  else:
    waitFor self.sendMessage(SendMessage(message: command))
