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
  WorkerTable = TableRef[string, tuple[kind: WorkerKind, worker: Worker]]
  TaskRunner* = ref object
    workers*: WorkerTable

proc newWorkerTable*(): WorkerTable =
  newTable[string, tuple[kind: WorkerKind, worker: Worker]]()

proc new*(T: type TaskRunner, workers: WorkerTable = newWorkerTable()): T =
  T(workers: workers)

proc start*(self: TaskRunner) {.async.} =
  for v in self.workers.values:
    let (kind, worker) = v
    case kind:
      of pool:
        await cast[PoolWorker](worker).start()
      of thread:
        await cast[ThreadWorker](worker).start()

proc stop*(self: TaskRunner) {.async.} =
  for v in self.workers.values:
    let (kind, worker) = v
    case kind:
      of pool:
        await cast[PoolWorker](worker).stop()
      of thread:
        await cast[ThreadWorker](worker).stop()

proc createWorker*(self: TaskRunner, kind: WorkerKind, name: string,
  context: Context = emptyContext, contextArg: ContextArg = ContextArg(),
  size = DefaultPoolSize) =
  case kind:
    of pool:
      self.workers[name] = (kind: kind,
        worker: PoolWorker.new(name, context, contextArg, size))
    of thread:
      self.workers[name] = (kind: kind,
        worker: ThreadWorker.new(name, context, contextArg))

# the `createTask` template needs to be implemented here because it needs to
# know about worker types, task types, and the `TaskRunner` type

# template createTask, ..., ..., ...

# need to pass name of task (generated helper proc will be assigned to
# `const [task_name]`), instance of `TaskRunner`, name of worker, `kind`, list
# of parameters to be used in subtype of `TaskArg` (generated by
# template/macro), and body of task; body will be wrapped in logic that handles
# the `rts` vs. `no_rts` behaviors; helper procs for `no_rts` tasks could
# always be sync and use `sendSync`; helper procs for rts tasks will need to be
# to be `{.async.}`, though it may be possible to also generate a
# `[task_name]Sync` variant that accepts a callback and works with the API of
# chronos `Future` directly
