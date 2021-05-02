import # vendor libs
  chronicles, chronos

import # chat libs
  ./worker

logScope:
  topics = "task-runner"

const DefaultWorkerPoolSize* = 16

type WorkerPool* = ref object of Worker
  size*: int

proc new*(T: type WorkerPool, name: string, context: Context = emptyContext,
  size: int = DefaultWorkerPoolSize): T =
  T(context: context, name: name, size: size)

proc start*(self: WorkerPool) {.async.} =
  trace "starting worker pool", name=self.name, size=self.size

proc stop*(self: WorkerPool) {.async.} =
  trace "stopping worker pool", name=self.name, size=self.size
