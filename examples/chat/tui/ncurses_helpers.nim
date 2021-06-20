import # vendor libs
  chronicles, ncurses

export ncurses

logScope:
  topics = "chat tui"

var LC_ALL* {.header: "<locale.h>".}: cint

proc setlocale*(category: cint, locale: cstring): cstring {.importc: "setlocale", header: "<locale.h>".}

template NCURSES_MOUSE_MASK(b, m: untyped): untyped = ((m) shl (((b) - 1) * 5))

const
  REPORT_MOUSE_POSITION* = NCURSES_MOUSE_MASK(6, 0o10'i32)
  ALL_MOUSE_EVENTS* = REPORT_MOUSE_POSITION - 1
