import # std libs
  tables

import # vendor libs
  chronicles, chronos, task_runner

import # chat libs
  ./tasks, ./workers

export tables, task_runner, tasks, workers

logScope:
  topics = "task-runner"

type
  WorkerContext = proc(): Future[void] {.gcsafe, nimcall.}
  WorkerTable = TableRef[string, tuple[kind: WorkerKind, worker: Worker]]
  TaskRunner* = ref object
    workers*: WorkerTable

# may eventually want to have ability to automatically serialize and send data
# from host thread to worker and pass it as arg to context, in which case
# WorkerContext signature will need to be `(arg: string): Future[void]`
const emptyContext*: WorkerContext = proc() {.async, gcsafe, nimcall.} = discard

proc newWorkerTable*(): WorkerTable =
  newTable[string, tuple[kind: WorkerKind, worker: Worker]]()

proc new*(T: type TaskRunner, workers: WorkerTable = newWorkerTable()): T =
  T(workers: workers)

proc start*(self: TaskRunner) =
  for v in self.workers.values:
    let (kind, worker) = v
    case kind:
      of pool:
        cast[WorkerPool](worker).start()
      of thread:
        cast[WorkerThread](worker).start()

proc stop*(self: TaskRunner) =
  for v in self.workers.values:
    let (kind, worker) = v
    case kind:
      of pool:
        cast[WorkerPool](worker).stop()
      of thread:
        cast[WorkerThread](worker).stop()

proc createWorker*(self: TaskRunner, kind: WorkerKind, name: string,
  context: WorkerContext = emptyContext, size = DefaultWorkerPoolSize) =
  case kind:
    of pool:
      self.workers[name] = (kind: kind, worker: WorkerPool.new(name, size))
    of thread:
      self.workers[name] = (kind: kind, worker: WorkerThread.new(name))

# the createTask template needs to be implemented here because it needs to know
# about worker types, task types, and the TaskRunner type

# template createTask, ..., ..., ...

# need to pass name of task (helper proc will be assigned to `const
# [task_name]`), instance of TaskRunner, name of worker, kind, list of
# parameters to be used in subtype of TaskArg (created by template/macro), and
# body of task; body will be wrapped in logic that handles all the async
# vs. sync and rts vs. non-rts behaviors (hopefully); if the latter aspect does
# work out then can probably change Task* so that all task procs are
# `{.async, gcsafe, nimcall.}` and the worker can always use asyncSpawn; helper
# procs for non-rts tasks could always be non-async and use `sendSync`; helper
# procs for rts tasks will need to be to be `{.async.}`, though it may be
# possible to also generate a `[task_name]Sync` variant that accepts a callback
# and works with the Future API directly

# ^ note Task* in ./tasks.nim has already been changed (re: ideas described
# above) so the signature is `(arg: string): Future[void]`
