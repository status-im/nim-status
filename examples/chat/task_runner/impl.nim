import # std libs
  atomics, macros, tables

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


# experimental -----------------------------------------------------------------

macro task*(kind: TaskKind, stoppable: bool, body: untyped): untyped =
  result = newStmtList()

  echo(kind)
  echo(stoppable)
  echo()

  echo(treeRepr body)
  echo()

  const
    star = "*"
    syncPost = "Sync"
    taskArgPost = "TaskArg"
    taskPost = "Task"

  var
    exported = ""
    taskArgName: NimNode
    taskName: NimNode
    taskNameImpl: NimNode
    taskNameSync: NimNode


  if kind(body[0]) == nnkPostfix:
    if body[0][0] == ident(star): exported = star
    let taskNameStr = strVal(body[0][1])
    taskArgName = ident(taskNameStr & taskArgPost)
    taskName = ident(taskNameStr & exported)
    taskNameImpl = ident(taskNameStr & taskPost)
    taskNameSync = ident(taskNameStr & syncPost & exported)


  else:
    taskName = body[0]
    let taskNameStr = strVal(taskName)
    taskArgName = ident(taskNameStr & taskArgPost)
    taskNameImpl = ident(taskNameStr & taskPost)
    taskNameSync = ident(taskNameStr & syncPost)


  echo taskArgName
  echo taskName
  echo taskNameSync
  echo taskNameImpl

  # debug ----------------------------------------------------------------------
  echo toStrLit(result)


macro task*(kind: TaskKind, body: untyped): untyped =
  result = newStmtList()
  result.add(quote do: task(`kind`, false, `body`))


macro task*(stoppable: bool, body: untyped): untyped =
  result = newStmtList()
  result.add(quote do: task(rts, `stoppable`, `body`))


macro task*(body: untyped): untyped =
  result = newStmtList()
  result.add(quote do: task(rts, false, `body`))


# usage ------------------------------------------------------------------------

proc hello*[T, U](name: string) {.task.} =
  echo "Hello, " & name & "!"
