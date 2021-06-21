import # std libs
  std/bitops

import # vendor libs
  chronicles, ncurses

export ncurses

logScope:
  topics = "chat tui"

template NCURSES_MOUSE_MASK(b, m: untyped): untyped = ((m) shl (((b) - 1) * 5))

const
  # TODO: implement `NCURSES_ACS` template in status-im/nim-ncurses
  # For now refer to:
  # http://melvilletheatre.com/articles/ncurses-extended-characters/index.html
  ACS_LTEE* = bitor(116.uint32, A_ALT_CHARSET).chtype
  ACS_RTEE* = bitor(117.uint32, A_ALT_CHARSET).chtype

  REPORT_MOUSE_POSITION* = NCURSES_MOUSE_MASK(6, 0o10'i32)
  ALL_MOUSE_EVENTS* = REPORT_MOUSE_POSITION - 1

var
  LC_ALL* {.header: "<locale.h>".}: cint

  COLS* {.importc: "COLS", dynlib: libncurses.}: cint
  LINES* {.importc: "LINES", dynlib: libncurses.}: cint

proc setlocale*(category: cint, locale: cstring): cstring {.
  importc: "setlocale", header: "<locale.h>".}
