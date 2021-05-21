import # chat libs
  ../client, ./ncurses_helpers

export client, ncurses_helpers

type
  ChatTUI* = ref object
    client*: ChatClient
    currentInput*: string
    dataDir*: string
    events*: EventChannel
    inputReady*: bool
    locale*: string
    mainWindow*: PWindow
    running*: bool
    taskRunner*: TaskRunner
  TUIEvent* = ref object of Event
  InputKey* = ref object of TUIEvent
    key*: int
    name*: string
  InputReady* = ref object of TUIEvent
    ready*: bool
  InputString* = ref object of TUIEvent
    str*: string

const TUIEvents* = [
  "InputKey",
  "InputReady",
  "InputString"
]
