import # std libs
  atomics, tables

import # vendor libs
  chronicles, chronos, task_runner

import # chat libs
  ./tasks, ./workers

export atomics, chronicles, chronos, tables, task_runner, tasks, workers

logScope:
  topics = "task_runner"

type
  WorkerTable = TableRef[string, tuple[kind: WorkerKind, worker: Worker]]
  TaskRunner* = ref object
    running*: Atomic[bool]
    workers*: WorkerTable

proc newWorkerTable*(): WorkerTable =
  newTable[string, tuple[kind: WorkerKind, worker: Worker]]()

proc new*(T: type TaskRunner, workers: WorkerTable = newWorkerTable()): T =
  # Atomic[bool] is `false` by default, no need to initialize `running`
  T(workers: workers)

proc start*(self: TaskRunner) {.async.} =
  trace "task runner starting"
  var starting: seq[Future[void]] = @[]
  for v in self.workers.values:
    let (kind, worker) = v
    case kind:
      of pool:
        starting.add cast[PoolWorker](worker).start()
      of thread:
        starting.add cast[ThreadWorker](worker).start()
  await allFutures(starting)
  trace "task runner started"
  self.running.store(true)

proc stop*(self: TaskRunner) {.async.} =
  trace "task runner stopping"
  self.running.store(false)
  var stopping: seq[Future[void]] = @[]
  for v in self.workers.values:
    let (kind, worker) = v
    case kind:
      of pool:
        stopping.add(cast[PoolWorker](worker).stop())
      of thread:
        stopping.add(cast[ThreadWorker](worker).stop())
  await allFutures(stopping)
  trace "task runner stopped"

proc createWorker*(self: TaskRunner, kind: WorkerKind, name: string,
  context: Context = emptyContext, contextArg: ContextArg = ContextArg(),
  size = DefaultPoolSize) =
  let running = cast[pointer](addr self.running)
  case kind:
    of pool:
      self.workers[name] = (kind: kind,
        worker: PoolWorker.new(name, running, context, contextArg, size))
    of thread:
      self.workers[name] = (kind: kind,
        worker: ThreadWorker.new(name, running, context, contextArg))

# the `createTask` template needs to be implemented here because it needs to
# know about worker types, task types, and the `TaskRunner` type

# template createTask, ..., ..., ...
