import # vendor libs
  ncurses

export ncurses

var LC_ALL* {.header: "<locale.h>".}: cint

proc setlocale*(category: cint, locale: cstring): cstring {.importc: "setlocale", header: "<locale.h>".}
