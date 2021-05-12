import # chat libs
  ./common, ./tasks

export tasks

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
