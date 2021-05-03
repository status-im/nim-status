import # std libs
  json

import # vendor libs
  chronicles, chronos, task_runner

import # chat libs
  ./worker

logScope:
  topics = "task-runner"

type
  WorkerThreadArg = ref object
    chanSendToHost: AsyncChannel[ThreadSafeString]
    chanRecvFromHost: AsyncChannel[ThreadSafeString]
    context: Context
    contextArg: ContextArg
    workerName: string
  WorkerThread* = ref object of Worker
    chanRecvFromThread: AsyncChannel[ThreadSafeString]
    chanSendToThread: AsyncChannel[ThreadSafeString]
    thread: Thread[WorkerThreadArg]

proc workerThread(arg: WorkerThreadArg) {.thread.}

proc new*(T: type WorkerThread, name: string,
  context: Context = emptyContext, contextArg: ContextArg = ContextArg()): T =
  let
    chanRecvFromThread = newAsyncChannel[ThreadSafeString](-1)
    chanSendToThread = newAsyncChannel[ThreadSafeString](-1)
    thread = Thread[WorkerThreadArg]()

  T(context: context, contextArg: contextArg, name: name,
    chanRecvFromThread: chanRecvFromThread, chanSendToThread: chanSendToThread,
    thread: thread)

proc start*(self: WorkerThread) {.async.} =
  trace "starting worker thread", worker=self.name
  self.chanRecvFromThread.open()
  self.chanSendToThread.open()
  let arg = WorkerThreadArg(
    chanRecvFromHost: self.chanSendToThread,
    chanSendToHost: self.chanRecvFromThread,
    context: self.context,
    contextArg: self.contextArg,
    workerName: self.name,
  )
  createThread(self.thread, workerThread, arg)
  trace "waiting for worker thread to start", worker=self.name
  discard $(await self.chanRecvFromThread.recv())

proc stop*(self: WorkerThread) {.async.} =
  trace "stopping worker thread", worker=self.name
  await self.chanSendToThread.send("stop".safe)
  self.chanRecvFromThread.close()
  self.chanSendToThread.close()
  trace "waiting for worker thread to stop", worker=self.name
  joinThread(self.thread)

proc worker(arg: WorkerThreadArg) {.async.} =
  let
    chanRecvFromHost = arg.chanRecvFromHost
    chanSendToHost = arg.chanSendToHost
    workerName = arg.workerName

  chanRecvFromHost.open()
  chanSendToHost.open()

  await arg.context(arg.contextArg)
  trace "worker thread sending notice to host", notice="ready",
    worker=workerName
  await chanSendToHost.send("ready".safe)

  while true:
    trace "worker thread waiting for message", worker=workerName
    let message = $(await chanRecvFromHost.recv())
    trace "worker thread received message", message=message, worker=workerName

    if message == "stop":
      trace "worker thread received 'stop'", worker=workerName
      break

    try:
      let
        parsed = parseJson(message)
        task = cast[Task](parsed{"tptr"}.getInt)
        taskName = parsed{"tname"}.getStr

      trace "worker thread initiating task", task=taskName, worker=workerName
      try:
        asyncSpawn task(message)
      except Exception as e:
        error "worker thread exception", error=e.msg, task=taskName,
          worker=workerName
    except:
      error "worker thread received unknown message", message=message,
        worker=workerName

  chanRecvFromHost.close()
  chanSendToHost.close()

proc workerThread(arg: WorkerThreadArg) {.thread.} =
  waitFor worker(arg)
