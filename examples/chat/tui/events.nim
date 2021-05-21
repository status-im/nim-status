import # chat libs
  ./actions, ./macros

export actions

# TUIEvent types are defined in ./common because multiple modules in this
# directory make use of them

logScope:
  topics = "chat"

proc dispatch(self: ChatTUI, event: string) {.gcsafe, nimcall.}

proc listenToClient(self: ChatTUI) {.async, gcsafe, nimcall.} =
  while self.client.running and self.running:
    let event = await self.client.events.recv()
    asyncSpawn self.events.send(event)

proc listenToInput(self: ChatTUI) {.async, gcsafe, nimcall.} =
  let worker = self.taskRunner.workers["input"].worker
  while self.running and self.taskRunner.running.load():
    let event = await worker.chanRecvFromWorker.recv()
    asyncSpawn self.events.send(event)

proc listen*(self: ChatTUI) {.async, gcsafe, nimcall.} =
  asyncSpawn self.listenToClient()
  asyncSpawn self.listenToInput()
  while self.running:
    let event = $(await self.events.recv())
    debug "TUI received event", event
    self.dispatch(event)

proc dispatch(self: ChatTUI, event: string) {.gcsafe, nimcall.} =
  var eventType: string
  try:
    eventType = parseJson(event){"$type"}.getStr().split(':')[0]
  except:
    eventType = ""

  eventCases()
