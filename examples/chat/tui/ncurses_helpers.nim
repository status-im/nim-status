import # vendor libs
  ncurses

export ncurses

proc setlocale*(category: cint, locale: cstring): cstring {.importc: "setlocale", header: "<locale.h>".}
