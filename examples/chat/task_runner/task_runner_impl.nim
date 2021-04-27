import # std libs
  tables

import # vendor libs
  chronicles, task_runner

import # chat libs
  ./workers

export tables, task_runner, workers

logScope:
  topics = "task-runner"

type
  WorkerTable = TableRef[string, tuple[kind: WorkerKind, worker: Worker]]
  TaskRunner* = ref object
    workers*: WorkerTable

proc newWorkerTable*(): WorkerTable =
  newTable[string, tuple[kind: WorkerKind, worker: Worker]]()

proc new*(T: type TaskRunner, workers: WorkerTable = newWorkerTable()): T =
  T(workers: workers)

proc start*(self: TaskRunner) =
  echo "starting task runner..."
  for v in self.workers.values:
    let (kind, worker) = v
    if kind == pool:
      cast[WorkerPool](worker).start()
    else:
      cast[WorkerThread](worker).start()

proc stop*(self: TaskRunner) =
  echo "stopping task runner..."
  for v in self.workers.values:
    let (kind, worker) = v
    if kind == pool:
      cast[WorkerPool](worker).stop()
    else:
      cast[WorkerThread](worker).stop()
