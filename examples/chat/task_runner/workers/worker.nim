import # vendor libs
  task_runner

import # chat libs
  ../tasks

export tasks, task_runner

logScope:
  topics = "task_runner"

type
  WorkerChannel* = AsyncChannel[ThreadSafeString]

  WorkerKind* = enum pool, thread

  ThreadArg* = ref object of RootObj
    awaitTasks*: bool
    chanRecvFromHost*: WorkerChannel
    chanSendToHost*: WorkerChannel
    context*: Context
    contextArg*: ContextArg
    running*: pointer

  Worker* = ref object of RootObj
    awaitTasks*: bool
    chanRecvFromWorker*: WorkerChannel
    chanSendToWorker*: WorkerChannel
    context*: Context
    contextArg*: ContextArg
    name*: string
    running*: pointer

proc newWorkerChannel*(): WorkerChannel =
  newAsyncChannel[ThreadSafeString](-1)
