import # std libs
  std/[atomics, json]

import # vendor libs
  chronicles, chronos, task_runner

import # chat libs
  ./worker

export json

logScope:
  topics = "task_runner"

type
  WorkerThreadArg = ref object of ThreadArg
    workerName: string

  ThreadWorker* = ref object of Worker
    thread: Thread[WorkerThreadArg]

proc workerThread(arg: WorkerThreadArg) {.thread.}

proc new*(T: type ThreadWorker, name: string, running: pointer,
  context: Context = emptyContext, contextArg: ContextArg = ContextArg(),
  awaitTasks = false): T =
  let
    chanRecvFromWorker = newWorkerChannel()
    chanSendToWorker = newWorkerChannel()
    thread = Thread[WorkerThreadArg]()

  T(awaitTasks: awaitTasks, chanRecvFromWorker: chanRecvFromWorker,
    chanSendToWorker: chanSendToWorker, context: context,
    contextArg: contextArg, name: name, running: running, thread: thread)

proc start*(self: ThreadWorker) {.async.} =
  trace "worker starting", worker=self.name
  self.chanRecvFromWorker.open()
  self.chanSendToWorker.open()
  let arg = WorkerThreadArg(awaitTasks: self.awaitTasks,
    chanRecvFromHost: self.chanSendToWorker,
    chanSendToHost: self.chanRecvFromWorker, context: self.context,
    contextArg: self.contextArg, running: self.running, workerName: self.name)

  createThread(self.thread, workerThread, arg)
  let notice = $(await self.chanRecvFromWorker.recv())
  trace "worker started", notice, worker=self.name

proc stop*(self: ThreadWorker) {.async.} =
  asyncSpawn self.chanSendToWorker.send("stop".safe)
  joinThread(self.thread)
  self.chanRecvFromWorker.close()
  self.chanSendToWorker.close()
  trace "worker stopped", worker=self.name

proc worker(arg: WorkerThreadArg) {.async.} =
  let
    awaitTasks = arg.awaitTasks
    chanRecvFromHost = arg.chanRecvFromHost
    chanSendToHost = arg.chanSendToHost
    worker = arg.workerName

  var running = cast[ptr Atomic[bool]](arg.running)

  chanRecvFromHost.open()
  chanSendToHost.open()

  trace "worker running context", worker
  await arg.context(arg.contextArg)
  let notice = "ready"
  trace "worker sent notification to host", notice, worker
  asyncSpawn chanSendToHost.send(notice.safe)

  while true:
    trace "worker waiting for message", worker
    let message = $(await chanRecvFromHost.recv())

    if message == "stop":
      trace "worker stopping", notice=message, worker
      break

    if running[].load():
      try:
        let
          parsed = parseJson(message)
          task = cast[Task](parsed{"task"}.getInt)
          taskName = parsed{"taskName"}.getStr

        trace "worker received message", message, worker
        trace "worker running task", task=taskName, worker

        if awaitTasks:
          await task(message)
        else:
          asyncSpawn task(message)

      except Exception as e:
        error "worker received unknown message", message, worker, error=e.msg

  chanRecvFromHost.close()
  chanSendToHost.close()

proc workerThread(arg: WorkerThreadArg) {.thread.} =
  waitFor worker(arg)
