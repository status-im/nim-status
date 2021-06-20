import # std libs
  atomics, json, sequtils, tables

import # vendor libs
  chronicles, chronos, task_runner

import # chat libs
  ./worker

export json

logScope:
  topics = "task_runner"

type
  PoolThreadArg = ref object of ThreadArg
    poolName: string
    poolSize: int

  PoolWorker* = ref object of Worker
    size*: int
    thread: Thread[PoolThreadArg]

  WorkerThreadArg = ref object of ThreadArg
    poolName: string
    workerId: int

  ThreadWorker = ref object of Worker
    id: int
    thread: Thread[WorkerThreadArg]

  WorkerNotification = ref object
    id: int
    notice: string

proc poolThread(arg: PoolThreadArg) {.thread.}

proc workerThread(arg: WorkerThreadArg) {.thread.}

const DefaultPoolSize* = 16

proc new*(T: type PoolWorker, name: string, running: pointer,
  context: Context = emptyContext, contextArg: ContextArg = ContextArg(),
  size: int = DefaultPoolSize, awaitTasks = true): T =
  let
    chanRecvFromWorker = newWorkerChannel()
    chanSendToWorker = newWorkerChannel()
    thread = Thread[PoolThreadArg]()

  T(awaitTasks: awaitTasks, chanRecvFromWorker: chanRecvFromWorker,
    chanSendToWorker: chanSendToWorker, context: context,
    contextArg: contextArg, name: name, running: running, size: size,
    thread: thread)

proc start*(self: PoolWorker) {.async.} =
  trace "pool starting", pool=self.name, poolSize=self.size
  self.chanRecvFromWorker.open()
  self.chanSendToWorker.open()
  let arg = PoolThreadArg(awaitTasks: self.awaitTasks,
    chanRecvFromHost: self.chanSendToWorker,
    chanSendToHost: self.chanRecvFromWorker, context: self.context,
    contextArg: self.contextArg, running: self.running, poolName: self.name,
    poolSize: self.size)

  createThread(self.thread, poolThread, arg)
  let notice = $(await self.chanRecvFromWorker.recv())
  trace "pool started", notice, pool=self.name, poolSize=self.size

proc stop*(self: PoolWorker) {.async.} =
  asyncSpawn self.chanSendToWorker.send("stop".safe)
  joinThread(self.thread)
  self.chanRecvFromWorker.close()
  self.chanSendToWorker.close()
  trace "pool stopped", pool=self.name, poolSize=self.size

proc new*(T: type ThreadWorker, name: string, id: int, running: pointer,
  chanRecvFromWorker: WorkerChannel, context: Context = emptyContext,
  contextArg: ContextArg = ContextArg(), awaitTasks = true): T =
  let
    chanSendToWorker = newWorkerChannel()
    thread = Thread[WorkerThreadArg]()

  T(awaitTasks: awaitTasks, chanRecvFromWorker: chanRecvFromWorker,
    chanSendToWorker: chanSendToWorker, context: context,
    contextArg: contextArg, name: name, running: running, id: id,
    thread: thread)

proc start*(self: ThreadWorker) {.async.} =
  self.chanSendToWorker.open()
  let arg = WorkerThreadArg(awaitTasks: self.awaitTasks,
    chanRecvFromHost: self.chanSendToWorker,
    chanSendToHost: self.chanRecvFromWorker, context: self.context,
    contextArg: self.contextArg, running: self.running, poolName: self.name,
    workerId: self.id)

  createThread(self.thread, workerThread, arg)

proc stop*(self: ThreadWorker) {.async.} =
  asyncSpawn self.chanSendToWorker.send("stop".safe)
  joinThread(self.thread)
  self.chanSendToWorker.close()
  trace "pool worker stopped", pool=self.name, workerId=self.id

proc pool(arg: PoolThreadArg) {.async.} =
  let
    chanRecvFromHostOrWorker = arg.chanRecvFromHost
    chanSendToHost = arg.chanSendToHost
    pool = arg.poolName
    poolSize = arg.poolSize

  var running = cast[ptr Atomic[bool]](arg.running)

  chanRecvFromHostOrWorker.open()
  chanSendToHost.open()

  let notice = "ready"
  trace "pool sent notification to host", notice, pool
  asyncSpawn chanSendToHost.send(notice.safe)

  var
    taskQueue: seq[string] = @[] # FIFO queue
    workersBusy = newTable[int, ThreadWorker]()
    workersIdle: seq[ThreadWorker] = @[]
    workersStarted = 0

  for i in 0..<poolSize:
    let
      workerId = i + 1
      worker = ThreadWorker.new(pool, workerId, arg.running,
        chanRecvFromHostOrWorker, arg.context, arg.contextArg, arg.awaitTasks)

    workersBusy[workerId] = worker
    trace "pool worker starting", pool, workerId
    trace "pool marked new worker as busy", pool, poolSize, workerId,
      workersStarted=workerId

    asyncSpawn worker.start()

  # when task received and number of busy threads == poolSize, then put task in
  # taskQueue

  # when task received and number of busy threads < poolSize, pop worker from
  # workersIdle, track that worker in workersBusy, and send task to that
  # worker; if taskQueue is not empty then before sending the current task it
  # should be added to the queue and replaced with oldest task in the queue

  # if "ready" or "done" received from a worker, remove worker from
  # workersBusy, and push worker into workersIdle

  while true:
    trace "pool waiting for message", pool
    var
      message = $(await chanRecvFromHostOrWorker.recv())
      shouldSendToWorker = false

    if message == "stop":
      trace "pool stopping", notice=message, pool, poolSize
      var stopping: seq[Future[void]] = @[]
      for worker in workersIdle:
        stopping.add worker.stop()
      for worker in workersBusy.values:
        stopping.add worker.stop()

      await allFutures(stopping)
      trace "pool workers all stopped", pool, poolSize
      break

    if running[].load():
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
                if notice == "ready":
                  trace "pool worker started", notice, pool, workerId
                  workersStarted = workersStarted + 1
                  if workersStarted == poolSize:
                    trace "pool workers all started", pool, poolSize

                workersBusy.del workerId
                workersIdle.add worker
                trace "pool marked worker as idle", notice, pool, poolSize,
                  workerId, workersBusy=workersBusy.len,
                  workersIdle=workersIdle.len

              else:
                error "pool received unknown notification from worker", notice,
                  pool, workerId

            except Exception as e:
              error "exception raised while handling pool worker notification",
                error=e.msg, notification=message, pool

          else: # it's a task to send to an idle worker or add to the taskQueue
            trace "pool received message", message, pool
            shouldSendToWorker = true

      except:
        error "pool received unknown message", message, pool

      if (not shouldSendToWorker) and taskQueue.len > 0 and
         workersBusy.len < poolSize:
        message = taskQueue[0]
        taskQueue.delete 0, 0
        trace "pool removed task from queue", pool, queued=taskQueue.len
        shouldSendToWorker = true

      elif shouldSendToWorker and taskQueue.len > 0 and
           workersBusy.len < poolSize:
        taskQueue.add message
        message = taskQueue[0]
        taskQueue.delete 0, 0
        trace "pool added task to queue and removed oldest task from queue",
          pool, queued=taskQueue.len

      elif shouldSendToWorker and workersBusy.len == poolSize:
        taskQueue.add message
        trace "pool added task to queue", pool, queued=taskQueue.len
        shouldSendToWorker = false

      if shouldSendToWorker:
        let
          worker = workersIdle[0]
          workerId = worker.id

        workersIdle.delete 0, 0
        workersBusy[workerId] = worker
        trace "pool sent task to worker", pool, workerId
        trace "pool marked worker as busy", pool, poolSize, workerId,
          workersBusy=workersBusy.len, workersIdle=workersIdle.len

        asyncSpawn worker.chanSendToWorker.send(message.safe)

  chanRecvFromHostOrWorker.close()
  chanSendToHost.close()

proc poolThread(arg: PoolThreadArg) {.thread.} =
  waitFor pool(arg)

proc worker(arg: WorkerThreadArg) {.async.} =
  let
    awaitTasks = arg.awaitTasks
    chanRecvFromHost = arg.chanRecvFromHost
    chanSendToHost = arg.chanSendToHost
    pool = arg.poolName
    workerId = arg.workerId

  var running = cast[ptr Atomic[bool]](arg.running)

  chanRecvFromHost.open()
  chanSendToHost.open()

  trace "pool worker running context", pool, workerId
  await arg.context(arg.contextArg)
  let
    notice = "ready"
    notification = WorkerNotification(id: workerId, notice: notice)

  trace "pool worker sent notification to pool", notice, pool, workerId
  asyncSpawn chanSendToHost.send(notification.encode.safe)

  while true:
    trace "pool worker waiting for message", pool, workerId
    let message = $(await chanRecvFromHost.recv())

    if message == "stop":
      trace "pool worker stopping", notice=message, pool, workerId
      break

    if running[].load():
      try:
        let
          parsed = parseJson(message)
          task = cast[Task](parsed{"task"}.getInt)
          taskName = parsed{"taskName"}.getStr

        trace "pool worker received message", message, pool, workerId
        trace "pool worker running task", pool, task=taskName, workerId

        if awaitTasks:
          await task(message)
        else:
          asyncSpawn task(message)

      except:
        error "pool worker received unknown message", message, pool, workerId

      let
        notice = "done"
        notification = WorkerNotification(id: workerId, notice: notice)

      trace "pool worker sent notification to pool", notice, pool, workerId
      asyncSpawn chanSendToHost.send(notification.encode.safe)

  chanRecvFromHost.close()
  chanSendToHost.close()

proc workerThread(arg: WorkerThreadArg) {.thread.} =
  waitFor worker(arg)
