import # std libs
  json, sequtils, tables

import # vendor libs
  chronicles, chronos, task_runner

import # chat libs
  ./worker

logScope:
  topics = "task-runner"

type
  PoolThreadArg = ref object
    chanSendToHost: WorkerChannel
    chanRecvFromHost: WorkerChannel
    context: Context
    contextArg: ContextArg
    poolName: string
    poolSize: int
  PoolWorker* = ref object of Worker
    chanRecvFromPool*: WorkerChannel
    chanSendToPool*: WorkerChannel
    size*: int
    thread: Thread[PoolThreadArg]
  WorkerThreadArg = ref object
    chanRecvFromPool: WorkerChannel
    chanSendToPool: WorkerChannel
    context: Context
    contextArg: ContextArg
    poolName: string
    workerId: int
  PoolWorkerThreadWorker = ref object of Worker
    chanRecvFromPoolWorker: WorkerChannel
    chanSendToPoolWorker: WorkerChannel
    id: int
    thread: Thread[WorkerThreadArg]
  WorkerNotification = ref object
    id: int
    notice: string

proc poolThread(arg: PoolThreadArg) {.thread.}

proc workerThread(arg: WorkerThreadArg) {.thread.}

const DefaultPoolSize* = 16

proc new*(T: type PoolWorker, name: string, context: Context = emptyContext,
  contextArg: ContextArg = ContextArg(), size: int = DefaultPoolSize): T =
  let
    chanRecvFromPool = newWorkerChannel()
    chanSendToPool = newWorkerChannel()
    thread = Thread[PoolThreadArg]()

  T(context: context, contextArg: contextArg, name: name,
    chanRecvFromPool: chanRecvFromPool, chanSendToPool: chanSendToPool,
    size: size, thread: thread)

proc start*(self: PoolWorker) {.async.} =
  trace "pool starting", pool=self.name, poolSize=self.size
  self.chanRecvFromPool.open()
  self.chanSendToPool.open()
  let arg = PoolThreadArg(
    chanRecvFromHost: self.chanSendToPool,
    chanSendToHost: self.chanRecvFromPool,
    context: self.context,
    contextArg: self.contextArg,
    poolName: self.name,
    poolSize: self.size
  )
  createThread(self.thread, poolThread, arg)
  discard $(await self.chanRecvFromPool.recv())
  trace "pool started", pool=self.name, poolSize=self.size

proc stop*(self: PoolWorker) {.async.} =
  await self.chanSendToPool.send("stop".safe)
  self.chanRecvFromPool.close()
  self.chanSendToPool.close()
  joinThread(self.thread)
  trace "pool stopped", pool=self.name, poolSize=self.size

proc new*(T: type PoolWorkerThreadWorker, name: string, id: int,
  chanRecvFromPoolWorker: WorkerChannel,
  context: Context = emptyContext, contextArg: ContextArg = ContextArg()): T =
  let
    chanSendToPoolWorker = newWorkerChannel()
    thread = Thread[WorkerThreadArg]()

  T(context: context, contextArg: contextArg, name: name,
    chanRecvFromPoolWorker: chanRecvFromPoolWorker,
    chanSendToPoolWorker: chanSendToPoolWorker, id: id, thread: thread)

proc start*(self: PoolWorkerThreadWorker) {.async.} =
  self.chanSendToPoolWorker.open()
  let arg = WorkerThreadArg(
    chanRecvFromPool: self.chanSendToPoolWorker,
    chanSendToPool: self.chanRecvFromPoolWorker,
    context: self.context,
    contextArg: self.contextArg,
    poolName: self.name,
    workerId: self.id
  )
  createThread(self.thread, workerThread, arg)

proc stop*(self: PoolWorkerThreadWorker) {.async.} =
  await self.chanSendToPoolWorker.send("stop".safe)
  self.chanSendToPoolWorker.close()
  joinThread(self.thread)
  trace "pool worker stopped", pool=self.name, workerId=self.id

proc pool(arg: PoolThreadArg) {.async.} =
  let
    chanRecvFromHostOrPoolWorker = arg.chanRecvFromHost
    chanSendToHost = arg.chanSendToHost
    pool = arg.poolName
    poolSize = arg.poolSize

  chanRecvFromHostOrPoolWorker.open()
  chanSendToHost.open()

  let notice = "ready"
  trace "pool sent notification to host", notice, pool
  await chanSendToHost.send(notice.safe)

  var
    taskQueue: seq[string] = @[] # FIFO queue
    workersBusy = newTable[int, PoolWorkerThreadWorker]()
    workersIdle: seq[PoolWorkerThreadWorker] = @[]
    workersStarted = 0

  for i in 0..<poolSize:
    let
      workerId = i + 1
      worker = PoolWorkerThreadWorker.new(pool, workerId,
        chanRecvFromHostOrPoolWorker, arg.context, arg.contextArg)

    workersBusy[workerId] = worker
    trace "pool worker starting", pool, workerId
    trace "pool marked new worker as busy", pool, poolSize, workerId,
      workersStarted=workerId
    asyncSpawn worker.start()

  # when task received and number of busy threads == poolSize, then put task in
  # taskQueue

  # when task received and number of busy threads < poolSize, pop a worker from
  # workersIdle, track that worker in workersBusy, and send task to that worker

  # if "ready" or "done" received from a worker, remove worker from
  # workersBusy, and push worker into workersIdle

  while true:
    trace "pool waiting for message", pool
    var
      message = $(await chanRecvFromHostOrPoolWorker.recv())
      shouldSendToWorker = false

    if message == "stop":
      trace "pool received notification from host", notice=message, pool
      trace "pool stopping", pool, poolSize
      for poolWorker in workersIdle:
        await poolWorker.stop()
      for poolWorker in workersBusy.values:
        await poolWorker.stop()
      trace "all pool workers stopped", pool, poolSize
      break

    try:
      let
        parsed = parseJson(message)
        messageType = parsed{"$type"}.getStr

      case messageType
        of "WorkerNotification:ObjectType":
          try:
            let
              notification = decode[WorkerNotification](message)
              workerId = notification.id
              notice = notification.notice
              worker = workersBusy[workerId]

            if notice == "ready" or notice == "done":
              trace "pool received notification from worker", notice, pool,
                workerId

              if notice == "ready":
                trace "pool worker started", pool, workerId
                workersStarted = workersStarted + 1
                if workersStarted == poolSize:
                  trace "all pool workers started", pool, poolSize

              workersBusy.del workerId
              workersIdle.add worker
              trace "pool marked worker as idle", pool, poolSize, workerId,
                workersBusy=workersBusy.len, workersIdle=workersIdle.len

            else:
              error "pool received unknown notification from worker", notice,
                pool, workerId

          except Exception as e:
            error "exception raised while handling pool worker notification",
              error=e.msg, message, pool

        else: # it's a task to send to an idle worker or add to the taskQueue
          trace "pool received message", message, pool
          if workersBusy.len == poolSize:
            taskQueue.add message
            trace "pool added task to queue", pool, queued=taskQueue.len
          else:
            shouldSendToWorker = true
            if taskQueue.len > 0:
              taskQueue.add message
              message = taskQueue[0]
              taskQueue.delete 0, 0
              trace "pool added task to queue and removed oldest task from queue",
                pool, queued=taskQueue.len

    except:
      error "pool received unknown message", message, pool

    if (not shouldSendToWorker) and taskQueue.len > 0 and
       workersBusy.len < poolSize:
      message = taskQueue[0]
      taskQueue.delete 0, 0
      trace "pool removed task from queue", pool, queued=taskQueue.len
      shouldSendToWorker = true

    if shouldSendToWorker:
      let
        worker = workersIdle[0]
        workerId = worker.id

      workersIdle.delete 0, 0
      workersBusy[workerId] = worker
      trace "pool sent task to worker", pool, workerId
      trace "pool marked worker as busy", pool, poolSize, workerId,
        workersBusy=workersBusy.len, workersIdle=workersIdle.len
      await worker.chanSendToPoolWorker.send(message.safe)

  chanRecvFromHostOrPoolWorker.close()
  chanSendToHost.close()

proc poolThread(arg: PoolThreadArg) {.thread.} =
  waitFor pool(arg)

proc worker(arg: WorkerThreadArg) {.async.} =
  let
    chanRecvFromPool = arg.chanRecvFromPool
    chanSendToPool = arg.chanSendToPool
    pool = arg.poolName
    workerId = arg.workerId

  chanRecvFromPool.open()
  chanSendToPool.open()

  trace "pool worker running context", pool, workerId
  await arg.context(arg.contextArg)
  let
    notice = "ready"
    notification = WorkerNotification(id: workerId, notice: notice)

  trace "pool worker sent notification to pool", notice, pool, workerId
  await chanSendToPool.send(notification.encode.safe)

  while true:
    trace "pool worker waiting for message", pool, workerId
    let message = $(await chanRecvFromPool.recv())

    if message == "stop":
      trace "pool worker received notification from pool", notice=message, pool,
        workerId
      trace "pool worker stopping", pool, workerId
      break

    try:
      let
        parsed = parseJson(message)
        task = cast[Task](parsed{"tptr"}.getInt)
        taskName = parsed{"tname"}.getStr

      trace "pool worker received message", message, pool, workerId
      trace "pool worker running task", pool, task=taskName, workerId
      asyncSpawn task(message)
    except:
      error "pool worker received unknown message", message, pool, workerId

    let
      notice = "done"
      notification = WorkerNotification(id: workerId, notice: notice)

    trace "pool worker sent notification to pool", notice, pool, workerId
    await chanSendToPool.send(notification.encode.safe)

  chanRecvFromPool.close()
  chanSendToPool.close()

proc workerThread(arg: WorkerThreadArg) {.thread.} =
  waitFor worker(arg)
