import # chat libs
  ./common

export common

logScope:
  topics = "chat"

# define Event types

proc listenToCounterWorker(self: ChatClient) {.async.} =
  let worker = self.taskRunner.workers["counter"].worker
  while self.running and self.taskRunner.running.load():
    let event = $(await worker.chanRecvFromWorker.recv())
    await self.events.send(event)

proc listen*(self: ChatClient) {.async.} =
  asyncSpawn self.listenToCounterWorker()
