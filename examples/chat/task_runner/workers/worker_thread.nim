import # std libs
  json

import # vendor libs
  chronicles, chronos, task_runner

import # chat libs
  ./worker

logScope:
  topics = "task-runner"

type
  WorkerThreadArg = object
    chanSendToHost: AsyncChannel[ThreadSafeString]
    chanRecvFromHost: AsyncChannel[ThreadSafeString]
  WorkerThread* = ref object of Worker
    chanRecvFromThread: AsyncChannel[ThreadSafeString]
    chanSendToThread: AsyncChannel[ThreadSafeString]
    thread: Thread[WorkerThreadArg]

proc workerThread(arg: WorkerThreadArg) {.thread.}

proc new*(T: type WorkerThread, name: string,
  context: Context = emptyContext): T =
  let
    chanRecvFromThread = newAsyncChannel[ThreadSafeString](-1)
    chanSendToThread = newAsyncChannel[ThreadSafeString](-1)
    thread = Thread[WorkerThreadArg]()

  T(context: context, name: name, chanRecvFromThread: chanRecvFromThread,
    chanSendToThread: chanSendToThread, thread: thread)

proc start*(self: WorkerThread) {.async.} =
  trace "starting worker thread", name=self.name

proc stop*(self: WorkerThread) {.async.} =
  trace "stopping worker thread", name=self.name
