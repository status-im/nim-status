import # vendor libs
  chronicles

import # chat libs
  ./worker

logScope:
  topics = "task-runner"

type WorkerThread* = ref object of Worker

proc new*(T: type WorkerThread, name: string): T =
  T(name: name)

proc start*(self: WorkerThread) =
  echo "starting worker thread named " & self.name & "..."

proc stop*(self: WorkerThread) =
  echo "stopping worker thread named " & self.name & "..."
