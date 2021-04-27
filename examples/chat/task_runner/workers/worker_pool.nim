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
  echo "starting worker pool named " & self.name &
    " (" & $self.size & " threads)..."

proc stop*(self: WorkerPool) =
  echo "stopping worker pool named " & self.name &
    " (" & $self.size & " threads)..."
