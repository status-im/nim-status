import # chat libs
  ../config, ../task_runner

export config, task_runner

type
  Event* = ref object of RootObj
  EventChannel* = AsyncChannel[ThreadSafeString]

  ChatClient* = ref object
    chatConfig*: ChatConfig
    events*: EventChannel
    running*: bool
    taskRunner*: TaskRunner

const status* = "status"

proc newEventChannel*(): EventChannel =
  newAsyncChannel[ThreadSafeString](-1)
