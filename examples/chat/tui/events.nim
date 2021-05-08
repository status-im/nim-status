import # chat libs
  ./common, ./tasks

export common, tasks

logScope:
  topics = "chat"

# Event types are defined in ./common because `dispatch` et al. in this module
# and the procs in ./tasks make use of them

proc dispatch*(self: ChatTUI, event: string) {.gcsafe, nimcall.}

proc listenToClient(self: ChatTUI) {.async.} =
  while self.client.running and self.running:
    let event = await self.client.events.recv()
    await self.events.send(event)

proc listenToInput(self: ChatTUI) {.async.} =
  let worker = self.taskRunner.workers["input"].worker
  while self.running:
    let event = $(await worker.chanRecvFromWorker.recv())
    await self.events.send(event)

proc listen*(self: ChatTUI) {.async.} =
  asyncSpawn self.listenToClient()
  asyncSpawn self.listenToInput()
  while self.running:
    let event = await self.events.recv()
    debug "TUI received event", event
    self.dispatch(event)

proc dispatch(self: ChatTUI, event: string) {.gcsafe, nimcall.} =
  # `event` should be parsed with std Json and `$type` checked that the string
  # starts with "Event", then decoded with decode[$type], else log an error that
  # an unknown event/message was received
  discard
