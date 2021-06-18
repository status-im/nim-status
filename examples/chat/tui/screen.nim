import # std libs
  std/[bitops, times]

import # chat libs
  ./common

export common

logScope:
  topics = "chat"

# NOTE: depending on the OS and/or terminal, font, and related software, there
# can be a problem with how ncurses displays some emojis and other characters,
# e.g. those that make use of ZWJ or ZWNJ and more generally known as "extended
# grapheme clusters"; there's not much that can be done about it at present:
# * https://stackoverflow.com/a/23533623
# * https://stackoverflow.com/a/54993513
# * https://en.wikipedia.org/wiki/Zero-width_joiner
# * https://en.wikipedia.org/wiki/Zero-width_non-joiner
# * https://unicode.org/glossary/#extended_grapheme_cluster

# CREDIT: the structure of this module was inspired by TBDChat
# https://github.com/mgeitz/tbdchat

let
  # TODO: implement `NCURSES_ACS` template in status-im/nim-ncurses
  # For now refer to:
  # http://melvilletheatre.com/articles/ncurses-extended-characters/index.html
  ACS_LTEE = bitor(116.uint32, A_ALT_CHARSET).chtype
  ACS_RTEE = bitor(117.uint32, A_ALT_CHARSET).chtype

var
  COLS {.importc: "COLS", dynlib: libncurses.}: cint
  LINES {.importc: "LINES", dynlib: libncurses.}: cint

proc clearInput*(self: ChatTUI) =
  var x, y: cint
  getyx(self.mainWin, y, x)
  move(y, 0)
  clrtoeol()
  refresh()

  trace "TUI cleared input window"

proc colors() =
  # TUI is using colors
  start_color()
  # use default terminal colors
  use_default_colors()

  # initialize color pairs
  init_pair(1, -1, -1) # Default
  init_pair(2, COLOR_CYAN, -1)
  init_pair(3, COLOR_YELLOW, -1)
  init_pair(4, COLOR_RED, -1)
  init_pair(5, COLOR_BLUE, -1)
  init_pair(6, COLOR_MAGENTA, -1)
  init_pair(7, COLOR_GREEN, -1)
  init_pair(8, COLOR_WHITE, COLOR_RED)

proc drawChatWin*(self: ChatTUI) =
  # create subwindow for the chat box
  self.chatWinBox = subwin(self.mainWin, (LINES.float64 * 0.8).cint, COLS, 0, 0)
  box(self.chatWinBox, 0, 0)

  # add title to the subwindow
  mvwaddch(self.chatWinBox, 0, ((COLS.float64 * 0.5).int - 9).cint, ACS_RTEE)
  wattron(self.chatWinBox, COLOR_PAIR(3).cint)
  mvwaddstr(self.chatWinBox, 0, ((COLS.float64 * 0.5).int - 8).cint,
    " nim-status chat ")
  wattroff(self.chatWinBox, COLOR_PAIR(3).cint)
  mvwaddch(self.chatWinBox, 0, ((COLS.float64 * 0.5).int + 9).cint, ACS_LTEE)

  # draw subwindow
  wrefresh(self.chatWinBox)

  # create sub subwindow to hold text
  self.chatWin = subwin(self.chatWinBox, ((LINES.float64 * 0.8).int - 2).cint,
    COLS - 2, 1, 1)

  # enable text scrolling
  scrollok(self.chatWin, true)

proc drawInfoLines*(self: ChatTUI) =
  # create info line above input window
  self.infoLine = subwin(self.mainWin, 1, COLS, (LINES.float64 * 0.8).cint, 0)

  # write initial text to info line
  wbkgd(self.infoLine, COLOR_PAIR(3).chtype)
  wprintw(self.infoLine, " Type /help to view a list of available commands")
  wrefresh(self.infoLine)

  # create lower info line
  self.infoLineBottom = subwin(self.mainWin, 1, COLS, LINES - 1, 0)

proc drawInputWin*(self: ChatTUI) =
  # create subwindow for the input box
  self.inputWinBox = subwin(self.mainWin, ((LINES.float64 * 0.2).int - 1).cint,
    COLS, ((LINES.float64 * 0.8).int + 1).cint, 0)
  box(self.inputWinBox, 0, 0)

  # draw subwindow
  wrefresh(self.inputWinBox)

  # create sub subwindow to hold input text
  self.inputWin = subwin(self.inputWinBox, ((LINES.float64 * 0.2).int - 3).cint,
    COLS - 2, ((LINES.float64 * 0.8).int + 2).cint, 1)

proc drawTermTooSmall*(self: ChatTUI) =
  discard

proc drawScreen*(self: ChatTUI) =
  if LINES < 24 or COLS < 76:
    self.drawTermTooSmall()
  else:
    self.drawChatWin()
    self.drawInputWin()
    self.drawInfoLines()

  trace "TUI drew initial screen"

proc initScreen*(): (string, PWindow) =
  # initialize ncurses
  let
    locale = $setlocale(LC_ALL, "")
    mainWin = initscr()

  refresh()

  trace "TUI set the locale", locale
  trace "TUI initialized ncurses"

  result = (locale, mainWin)

  # `halfdelay(N)` will cause ncurses' `getch()` (used in ./tui/tasks) to
  # return -1 after N tenths of a second if no input was supplied
  halfdelay(1)
  noecho()
  keypad(mainWin, true)
  setescdelay(0)
  colors()

proc printInput*(self: ChatTUI, input: string) =
  printw(input)
  refresh()

  trace "TUI printed in input window"

proc printMessage*(self: ChatTUI, message: string, timestamp: int64,
  username: string) =
  let tstamp = timestamp.fromUnix().local().format("'<'MMM' 'dd,' 'HH:mm'>'")
  printw("\n" & tstamp & " " & username & ": " & message)
  refresh()

  trace "TUI printed in message window"

proc resizeScreen*(self: ChatTUI) =
  # end current windows
  endwin()
  refresh()
  clear()

  if LINES < 24 or COLS < 76:
    self.drawTermTooSmall()
  else:
    # redraw windows
    self.drawChatWin()
    self.drawInputWin()
    self.drawInfoLines()

    # redraw ascii splash
    # asciiSplash()

    # refresh and move cursor to input window
    wrefresh(self.chatWin)
    wcursyncup(self.inputWin)
    wrefresh(self.inputWin)
