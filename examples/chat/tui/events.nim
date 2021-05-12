import # chat libs
  ./actions

export actions

# TUI Event types are defined in ./common because multiple modules in this
# directory make use of them

logScope:
  topics = "chat"

proc dispatch(self: ChatTUI, eventEnc: string) {.gcsafe, nimcall.}

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

proc dispatch(self: ChatTUI, eventEnc: string) {.gcsafe, nimcall.} =
  var eventType: string
  try:
    eventType = parseJson(eventEnc){"$type"}.getStr().split(':')[0]
  except:
    eventType = ""

  case eventType:
    of "InputKey":
      discard
      waitFor self.processKey(decode[InputKey](eventEnc))

    of "InputReady":
      waitFor self.processReady(decode[InputReady](eventEnc))

    of "InputString":
      waitFor self.processInput(decode[InputString](eventEnc))

    else:
      error "TUI received unknown event type", event=eventEnc
