import # std libs
  json, sequtils, tables

import # vendor libs
  chronicles, chronos, task_runner

import # chat libs
  ./worker

logScope:
  topics = "task-runner"

type
  WorkerPoolThreadArg = ref object
    chanSendToHost: AsyncChannel[ThreadSafeString]
    chanRecvFromHost: AsyncChannel[ThreadSafeString]
    context: Context
    contextArg: ContextArg
    poolName: string
    poolSize: int
  WorkerPool* = ref object of Worker
    chanRecvFromPool*: AsyncChannel[ThreadSafeString]
    chanSendToPool*: AsyncChannel[ThreadSafeString]
    size*: int
    thread: Thread[WorkerPoolThreadArg]
  WorkerPoolWorkerThreadArg = ref object
    chanRecvFromPool: AsyncChannel[ThreadSafeString]
    chanSendToPool: AsyncChannel[ThreadSafeString]
    context: Context
    contextArg: ContextArg
    poolName: string
    workerId: int
  WorkerPoolWorkerThread = ref object of Worker
    chanRecvFromPoolWorker: AsyncChannel[ThreadSafeString]
    chanSendToPoolWorker: AsyncChannel[ThreadSafeString]
    id: int
    thread: Thread[WorkerPoolWorkerThreadArg]
  WorkerNotification = ref object
    id: int
    notice: string

proc poolThread(arg: WorkerPoolThreadArg) {.thread.}

proc workerThread(arg: WorkerPoolWorkerThreadArg) {.thread.}

const DefaultWorkerPoolSize* = 16

proc new*(T: type WorkerPool, name: string, context: Context = emptyContext,
  contextArg: ContextArg = ContextArg(), size: int = DefaultWorkerPoolSize): T =
  let
    chanRecvFromPool = newAsyncChannel[ThreadSafeString](-1)
    chanSendToPool = newAsyncChannel[ThreadSafeString](-1)
    thread = Thread[WorkerPoolThreadArg]()

  T(context: context, contextArg: contextArg, name: name,
    chanRecvFromPool: chanRecvFromPool, chanSendToPool: chanSendToPool,
    size: size, thread: thread)

proc start*(self: WorkerPool) {.async.} =
  trace "starting worker pool", pool=self.name, size=self.size
  self.chanRecvFromPool.open()
  self.chanSendToPool.open()
  let arg = WorkerPoolThreadArg(
    chanRecvFromHost: self.chanSendToPool,
    chanSendToHost: self.chanRecvFromPool,
    context: self.context,
    contextArg: self.contextArg,
    poolName: self.name,
    poolSize: self.size
  )
  createThread(self.thread, poolThread, arg)
  trace "waiting for workers to start", pool=self.name, size=self.size
  discard $(await self.chanRecvFromPool.recv())

proc stop*(self: WorkerPool) {.async.} =
  trace "stopping worker pool", pool=self.name, size=self.size
  await self.chanSendToPool.send("stop".safe)
  self.chanRecvFromPool.close()
  self.chanSendToPool.close()
  trace "waiting for workers to stop", pool=self.name, size=self.size
  joinThread(self.thread)

proc new*(T: type WorkerPoolWorkerThread, name: string, id: int,
  chanRecvFromPoolWorker: AsyncChannel[ThreadSafeString],
  context: Context = emptyContext, contextArg: ContextArg = ContextArg()): T =
  let
    chanSendToPoolWorker = newAsyncChannel[ThreadSafeString](-1)
    thread = Thread[WorkerPoolWorkerThreadArg]()

  T(context: context, contextArg: contextArg, name: name,
    chanRecvFromPoolWorker: chanRecvFromPoolWorker,
    chanSendToPoolWorker: chanSendToPoolWorker, id: id, thread: thread)

proc start*(self: WorkerPoolWorkerThread) {.async.} =
  trace "starting pool worker thread", pool=self.name, workerId=self.id
  self.chanSendToPoolWorker.open()
  let arg = WorkerPoolWorkerThreadArg(
    chanRecvFromPool: self.chanSendToPoolWorker,
    chanSendToPool: self.chanRecvFromPoolWorker,
    context: self.context,
    contextArg: self.contextArg,
    poolName: self.name,
    workerId: self.id
  )
  createThread(self.thread, workerThread, arg)

proc stop*(self: WorkerPoolWorkerThread) {.async.} =
  trace "stopping pool worker thread", pool=self.name, workerId=self.id
  await self.chanSendToPoolWorker.send("stop".safe)
  self.chanSendToPoolWorker.close()
  joinThread(self.thread)

proc worker(arg: WorkerPoolWorkerThreadArg) {.async.} =
  let
    chanRecvFromPool = arg.chanRecvFromPool
    chanSendToPool = arg.chanSendToPool
    poolName = arg.poolName
    workerId = arg.workerId

  chanRecvFromPool.open()
  chanSendToPool.open()

  await arg.context(arg.contextArg)
  let notice = WorkerNotification(id: workerId, notice: "ready")
  trace "pool worker sending notice to pool", notice=notice.notice,
    pool=poolName, workerId=workerId
  await chanSendToPool.send(notice.encode.safe)

  while true:
    trace "pool worker waiting for message", pool=poolName, workerId=workerId
    let message = $(await chanRecvFromPool.recv())
    trace "pool worker received message", message=message, pool=poolName,
      workerId=workerId

    if message == "stop":
      trace "pool worker received 'stop'", pool=poolName, workerId=workerId
      break

    try:
      let
        parsed = parseJson(message)
        task = cast[Task](parsed{"tptr"}.getInt)
        taskName = parsed{"tname"}.getStr

      trace "pool worker initiating task", pool=poolName, task=taskName,
        workerId=workerId
      try:
        asyncSpawn task(message)
      except Exception as e:
        error "pool worker exception", error=e.msg, pool=poolName, task=taskName,
          workerId=workerId
    except:
      error "pool worker received unknown message", message=message,
        pool=poolName, workerId=workerId

    let notice = WorkerNotification(id: workerId, notice: "done")
    trace "pool worker sending notice to pool", notice=notice.notice,
      pool=poolName, workerId=workerId
    await chanSendToPool.send(notice.encode.safe)

  chanRecvFromPool.close()
  chanSendToPool.close()

proc pool(arg: WorkerPoolThreadArg) {.async.} =
  let
    chanRecvFromHostOrPoolWorker = arg.chanRecvFromHost
    chanSendToHost = arg.chanSendToHost
    poolName = arg.poolName
    poolSize = arg.poolSize

  chanRecvFromHostOrPoolWorker.open()
  chanSendToHost.open()

  var
    workersBusy = newTable[int, WorkerPoolWorkerThread]()
    workersIdle = newSeq[WorkerPoolWorkerThread](poolSize)
    taskQueue: seq[string] = @[] # FIFO queue
    allReady = 0

  await chanSendToHost.send("ready".safe)

  trace "worker pool starting workers", pool=poolName
  for i in 0..<poolSize:
    let
      id = i + 1
      poolWorker = WorkerPoolWorkerThread.new(poolName, id,
        chanRecvFromHostOrPoolWorker, arg.context, arg.contextArg)

    asyncSpawn poolWorker.start()
    trace "adding worker to workersIdle", pool=poolName, workerId=id
    workersIdle[i] = poolWorker

  # when task received and number of busy threads == poolSize, then put task in
  # a queue

  # when task received and number of busy threads < poolSize, pop a worker from
  # workersIdle, track that worker in workersBusy, and send task to that worker

  # if "done" received from a worker, remove worker from workersBusy, and push
  # worker into workersIdle

  while true:
    trace "worker pool waiting for message", pool=poolName
    var message = $(await chanRecvFromHostOrPoolWorker.recv())
    trace "worker pool received message", message=message, pool=poolName

    if message == "stop":
      trace "worker pool received 'stop'", pool=poolName
      trace "worker pool stopping workers", pool=poolName
      for poolWorker in workersIdle:
        asyncSpawn poolWorker.stop()
      for poolWorker in workersBusy.values:
        asyncSpawn poolWorker.stop()
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

            if notice == "ready":
              allReady = allReady + 1
              trace "received 'ready' from a worker", allReady=allReady,
                pool=poolName, workerId=workerId

            elif notice == "done":
              let poolWorker = workersBusy[workerId]
              trace "adding worker to workersIdle",
                newLength=(workersIdle.len + 1), pool=poolName,
                workerId=workerId
              workersIdle.add poolWorker
              trace "removing worker from workersBusy",
                newLength=(workersBusy.len - 1), pool=poolName,
                workerId=poolWorker.id
              workersBusy.del workerId

              if taskQueue.len > 0:
                trace "removing message from taskQueue",
                  newlength=(taskQueue.len - 1), pool=poolName
                message = taskQueue[0]
                taskQueue.delete 0, 0

                trace "removing worker from workersIdle",
                  newLength=(workersIdle.len - 1), pool=poolName
                let poolWorker = workersIdle[0]
                workersIdle.delete 0, 0
                trace "adding worker to workersBusy",
                  newLength=(workersBusy.len + 1), pool=poolName,
                  workerId=poolWorker.id
                workersBusy.add poolWorker.id, poolWorker
                trace "sending task to worker", pool=poolName,
                  workerId=poolWorker.id
                await poolWorker.chanSendToPoolWorker.send(message.safe)

            else:
              error "unknown worker notification", notice=notice, pool=poolName,
                workerId=workerId

          except Exception as e:
            error "unknown error while handling worker notification",
              error=e.msg, message=message, pool=poolName

        else: # it's a task to send to an idle worker or add to the taskQueue
          if allReady < poolSize or workersBusy.len == poolSize:
            trace "adding message to taskQueue", newLength=(taskQueue.len + 1),
              pool=poolName
            taskQueue.add message

          else:
            if taskQueue.len > 0:
              trace "adding message to taskQueue",
                newLength=(taskQueue.len + 1), pool=poolName
              taskQueue.add message
              trace "removing message from taskQueue",
                newlength=(taskQueue.len - 1), pool=poolName
              message = taskQueue[0]
              taskQueue.delete 0, 0

            trace "removing worker from workersIdle",
              newLength=(workersIdle.len - 1), pool=poolName
            let poolWorker = workersIdle[0]
            workersIdle.delete 0, 0
            trace "adding worker to workersBusy",
              newLength=(workersBusy.len + 1), pool=poolName,
              workerId=poolWorker.id
            workersBusy.add poolWorker.id, poolWorker
            trace "sending task to worker", pool=poolName,
              workerId=poolWorker.id
            await poolWorker.chanSendToPoolWorker.send(message.safe)

    except:
      error "worker pool received unknown message", message=message,
        pool=poolName

  chanRecvFromHostOrPoolWorker.close()
  chanSendToHost.close()

proc poolThread(arg: WorkerPoolThreadArg) {.thread.} =
  waitFor pool(arg)

proc workerThread(arg: WorkerPoolWorkerThreadArg) {.thread.} =
  waitFor worker(arg)
