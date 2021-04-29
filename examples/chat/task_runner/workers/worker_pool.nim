import # vendor libs
  chronicles

import # chat libs
  ./worker

logScope:
  topics = "task-runner"

const DefaultWorkerPoolSize* = 16

type WorkerPool* = ref object of Worker
  size*: int

proc new*(T: type WorkerPool, name: string, size: int = DefaultWorkerPoolSize): T =
  T(name: name, size: size)

proc start*(self: WorkerPool) =
  trace "starting worker pool", name=self.name, size=self.size

proc stop*(self: WorkerPool) =
  trace "stopping worker pool", name=self.name, size=self.size
