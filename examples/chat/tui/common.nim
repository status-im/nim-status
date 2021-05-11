import # vendor libs
  ncurses

import # chat libs
  ../client

export client, ncurses

type
  ChatTUI* = ref object
    client*: ChatClient
    currentInput*: string
    dataDir*: string
    events*: EventChannel
    locale*: string
    mainWindow*: PWindow
    running*: bool
    taskRunner*: TaskRunner
  InputKeyEvent* = ref object
    key*: int
    name*: string
  InputStringEvent* = ref object
    str*: string

var LC_ALL* {.header: "<locale.h>".}: cint

proc setlocale*(category: cint, locale: cstring): cstring {.importc: "setlocale", header: "<locale.h>".}
