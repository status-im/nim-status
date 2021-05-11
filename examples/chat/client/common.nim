import # chat libs
  ../task_runner

export task_runner

type
  EventChannel* = AsyncChannel[ThreadSafeString]
  ChatClient* = ref object
    dataDir*: string
    events*: EventChannel
    running*: bool
    taskRunner*: TaskRunner

proc newEventChannel*(): EventChannel =
  newAsyncChannel[ThreadSafeString](-1)
