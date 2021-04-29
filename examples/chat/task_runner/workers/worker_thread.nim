import # vendor libs
  chronicles, chronos

import # chat libs
  ./worker

logScope:
  topics = "task-runner"

type WorkerThread* = ref object of Worker

proc new*(T: type WorkerThread, name: string): T =
  T(name: name)

proc start*(self: WorkerThread) {.async.} =
  trace "starting worker thread", name=self.name

proc stop*(self: WorkerThread) {.async.} =
  trace "stopping worker thread", name=self.name
