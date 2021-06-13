import # chat libs
  ../task_runner

export task_runner

type
  Event* = ref object of RootObj
  EventChannel* = AsyncChannel[ThreadSafeString]
  ChatClient* = ref object
    dataDir*: string
    events*: EventChannel
    running*: bool
    taskRunner*: TaskRunner

const status* = "status"

proc newEventChannel*(): EventChannel =
  newAsyncChannel[ThreadSafeString](-1)
