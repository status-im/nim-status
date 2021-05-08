import # chat libs
  ../task_runner

export task_runner

type
  EventChannel* = AsyncChannel[string]
  ChatClient* = ref object
    dataDir*: string
    events*: EventChannel
    running*: bool
    taskRunner*: TaskRunner

proc newEventChannel*(): EventChannel =
  newAsyncChannel[string](-1)
