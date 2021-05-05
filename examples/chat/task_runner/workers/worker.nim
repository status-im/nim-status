import # vendor libs
  task_runner

import # chat libs
  ../tasks

export tasks, task_runner

type
  WorkerChannel* = AsyncChannel[ThreadSafeString]
  Worker* = ref object of RootObj
    chanRecvFromWorker*: WorkerChannel
    chanSendToWorker*: WorkerChannel
    context*: Context
    contextArg*: ContextArg
    name*: string

proc newWorkerChannel*(): WorkerChannel =
  newAsyncChannel[ThreadSafeString](-1)
