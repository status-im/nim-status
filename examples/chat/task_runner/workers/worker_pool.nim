import # vendor libs
  chronicles, chronos, task_runner

import # chat libs
  ./worker

logScope:
  topics = "task-runner"

type
  WorkerPoolArg = ref object
    chanSendToHost: AsyncChannel[ThreadSafeString]
    chanRecvFromHost: AsyncChannel[ThreadSafeString]
    context: Context
    contextArg: ContextArg
    poolName: string
    size: int
  WorkerPool* = ref object of Worker
    chanRecvFromPool: AsyncChannel[ThreadSafeString]
    chanSendToPool: AsyncChannel[ThreadSafeString]
    size: int
    thread: Thread[WorkerPoolArg]
  WorkerPoolThreadArg = ref object
    chanSendToHost: AsyncChannel[ThreadSafeString]
    chanSendToPoolManager: AsyncChannel[ThreadSafeString]
    chanRecvFromPoolManager: AsyncChannel[ThreadSafeString]
    context: Context
    contextArg: ContextArg
    poolName: string
  WorkerPoolThread = ref object of Worker
    chanRecvFromPoolThread: AsyncChannel[ThreadSafeString]
    chanSendToPoolThread: AsyncChannel[ThreadSafeString]
    thread: Thread[WorkerPoolThreadArg]

proc poolThread(arg: WorkerPoolArg) {.thread.}

const DefaultWorkerPoolSize* = 16

proc new*(T: type WorkerPool, name: string, context: Context = emptyContext,
  contextArg: ContextArg = ContextArg(), size: int = DefaultWorkerPoolSize): T =
  T(context: context, contextArg: contextArg, name: name, size: size)

proc start*(self: WorkerPool) {.async.} =
  trace "starting worker pool", name=self.name, size=self.size

proc stop*(self: WorkerPool) {.async.} =
  trace "stopping worker pool", name=self.name, size=self.size
