import # vendor libs
  task_runner

import # chat libs
  ../tasks

export tasks, task_runner

type
  Worker* = ref object of RootObj
    context*: Context
    contextArg*: ContextArg
    name*: string
  WorkerChannel* = AsyncChannel[ThreadSafeString]

proc newWorkerChannel*(): WorkerChannel =
  newAsyncChannel[ThreadSafeString](-1)
