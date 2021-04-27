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
  WorkerContext = proc(): void {.gcsafe, nimcall.}
  WorkerTable = TableRef[string, tuple[kind: WorkerKind, worker: Worker]]
  TaskRunner* = ref object
    workers*: WorkerTable

const emptyContext*: WorkerContext = proc() {.gcsafe, nimcall.} = discard

proc newWorkerTable*(): WorkerTable =
  newTable[string, tuple[kind: WorkerKind, worker: Worker]]()

proc new*(T: type TaskRunner, workers: WorkerTable = newWorkerTable()): T =
  T(workers: workers)

proc start*(self: TaskRunner) =
  echo "starting task runner..."
  for v in self.workers.values:
    let (kind, worker) = v
    case kind:
      of pool:
        cast[WorkerPool](worker).start()
      of thread:
        cast[WorkerThread](worker).start()

proc stop*(self: TaskRunner) =
  echo "stopping task runner..."
  for v in self.workers.values:
    let (kind, worker) = v
    case kind:
      of pool:
        cast[WorkerPool](worker).stop()
      of thread:
        cast[WorkerThread](worker).stop()

proc worker*(self: TaskRunner, kind: WorkerKind, name: string,
             context: WorkerContext = emptyContext,
             size = DefaultWorkerPoolSize) =
  case kind:
    of pool:
      self.workers[name] = (kind: kind, worker: WorkerPool.new(name, size))
    of thread:
      self.workers[name] = (kind: kind, worker: WorkerThread.new(name))
