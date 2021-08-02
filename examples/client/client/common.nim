import # client modules
  ../common

export common

logScope:
  topics = "client"

type
  Client* = ref object
    clientConfig*: ClientConfig
    currentTopic*: ContentTopic
    events*: EventChannel
    running*: bool
    taskRunner*: TaskRunner
    topics*: OrderedSet[ContentTopic]
