import # client libs
  ./actions

export actions

logScope:
  topics = "tui"

# TuiEvent types are defined in ./common to avoid circular dependency

proc dispatch(self: Tui, event: string) {.gcsafe, nimcall.} =
  var eventType: string
  try:
    eventType = parseJson(event){"$type"}.getStr().split(':')[0]
  except:
    eventType = ""

  eventCases()

proc listenToClient(self: Tui) {.async, gcsafe, nimcall.} =
  while self.client.running and self.running:
    let event = await self.client.events.recv()
    asyncSpawn self.events.send(event)

proc listenToInput(self: Tui) {.async, gcsafe, nimcall.} =
  let worker = self.taskRunner.workers["input"].worker
  while self.running and self.taskRunner.running.load():
    let event = await worker.chanRecvFromWorker.recv()
    asyncSpawn self.events.send(event)

proc listen*(self: Tui) {.async, gcsafe, nimcall.} =
  asyncSpawn self.listenToClient()
  asyncSpawn self.listenToInput()
  while self.running:
    let event = $(await self.events.recv())
    trace "TUI received event", event
    self.dispatch(event)
