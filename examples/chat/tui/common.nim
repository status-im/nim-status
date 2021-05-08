import # chat libs
  ../client

export client

# define Event types

type
  ChatTUI* = ref object
    client*: ChatClient
    dataDir*: string
    events*: EventChannel
    running*: bool
    taskRunner*: TaskRunner
