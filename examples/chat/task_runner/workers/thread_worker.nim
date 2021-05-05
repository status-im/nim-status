import # std libs
  json

import # vendor libs
  chronicles, chronos, task_runner

import # chat libs
  ./worker

logScope:
  topics = "task-runner"

type
  ThreadArg = ref object
    chanSendToHost: WorkerChannel
    chanRecvFromHost: WorkerChannel
    context: Context
    contextArg: ContextArg
    workerName: string
  ThreadWorker* = ref object of Worker
    thread: Thread[ThreadArg]

proc workerThread(arg: ThreadArg) {.thread.}

proc new*(T: type ThreadWorker, name: string,
  context: Context = emptyContext, contextArg: ContextArg = ContextArg()): T =
  let
    chanRecvFromWorker = newWorkerChannel()
    chanSendToWorker = newWorkerChannel()
    thread = Thread[ThreadArg]()

  T(context: context, contextArg: contextArg, name: name,
    chanRecvFromWorker: chanRecvFromWorker, chanSendToWorker: chanSendToWorker,
    thread: thread)

proc start*(self: ThreadWorker) {.async.} =
  trace "worker starting", worker=self.name
  self.chanRecvFromWorker.open()
  self.chanSendToWorker.open()
  let arg = ThreadArg(
    chanRecvFromHost: self.chanSendToWorker,
    chanSendToHost: self.chanRecvFromWorker,
    context: self.context,
    contextArg: self.contextArg,
    workerName: self.name,
  )
  createThread(self.thread, workerThread, arg)
  discard $(await self.chanRecvFromWorker.recv())
  trace "worker started", worker=self.name

proc stop*(self: ThreadWorker) {.async.} =
  await self.chanSendToWorker.send("stop".safe)
  self.chanRecvFromWorker.close()
  self.chanSendToWorker.close()
  joinThread(self.thread)
  trace "worker stopped", worker=self.name

proc worker(arg: ThreadArg) {.async.} =
  let
    chanRecvFromHost = arg.chanRecvFromHost
    chanSendToHost = arg.chanSendToHost
    worker = arg.workerName

  chanRecvFromHost.open()
  chanSendToHost.open()

  trace "worker running context", worker
  await arg.context(arg.contextArg)
  let notice = "ready"
  trace "worker sent notification to host", notice, worker
  await chanSendToHost.send(notice.safe)

  while true:
    trace "worker waiting for message", worker
    let message = $(await chanRecvFromHost.recv())

    if message == "stop":
      trace "worker received notification from host", notice=message, worker
      trace "worker stopping", worker
      break

    try:
      let
        parsed = parseJson(message)
        task = cast[Task](parsed{"tptr"}.getInt)
        taskName = parsed{"tname"}.getStr

      trace "worker received message", message, worker
      trace "worker running task", task=taskName, worker
      asyncSpawn task(message)
    except:
      error "worker received unknown message", message, worker

  chanRecvFromHost.close()
  chanSendToHost.close()

proc workerThread(arg: ThreadArg) {.thread.} =
  waitFor worker(arg)
