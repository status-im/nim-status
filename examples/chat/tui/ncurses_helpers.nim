import # std libs
  std/bitops

import # vendor libs
  chronicles, ncurses

export ncurses

logScope:
  topics = "chat tui"

# NOTE: depending on OS, terminal emulator, font, and related software, there
# can be problems re: how ncurses displays some emojis and other characters,
# e.g. those that make use of ZWJ or ZWNJ (more generally "extended grapheme
# clusters"); there's not much that can be done about it at present:
# * https://en.wikipedia.org/wiki/Zero-width_joiner
# * https://en.wikipedia.org/wiki/Zero-width_non-joiner
# * https://stackoverflow.com/a/23533623
# * https://stackoverflow.com/a/54993513
# * https://unicode.org/glossary/#extended_grapheme_cluster

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
