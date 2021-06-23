import # chat libs
  ./common

export common

logScope:
  topics = "chat client"

type
  ClientEvent* = ref object of Event

  NetworkStatus* = ref object of ClientEvent
    online*: bool

  UserMessage* = ref object of ClientEvent
    message*: string
    timestamp*: int64
    username*: string

const clientEvents* = [
  "NetworkStatus",
  "UserMessage"
]

proc listenToStatus(self: ChatClient) {.async.} =
  let worker = self.taskRunner.workers["status"].worker
  while self.running and self.taskRunner.running.load():
    let event = await worker.chanRecvFromWorker.recv()
    asyncSpawn self.events.send(event)

proc listen*(self: ChatClient) {.async.} =
  asyncSpawn self.listenToStatus()
