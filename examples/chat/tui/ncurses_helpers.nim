import # vendor libs
  chronicles, ncurses

export ncurses

logScope:
  topics = "chat tui"

var LC_ALL* {.header: "<locale.h>".}: cint

proc setlocale*(category: cint, locale: cstring): cstring {.importc: "setlocale", header: "<locale.h>".}
