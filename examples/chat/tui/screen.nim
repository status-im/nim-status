import # std libs
  std/[bitops, times]

import # chat libs
  ./common

export common

logScope:
  topics = "chat tui"

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
  getyx(self.inputWin, y, x)
  wmove(self.inputWin, y, 0)
  wclrtoeol(self.inputWin)
  wrefresh(self.inputWin)

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

    # move cursor to input window and refresh
    wcursyncup(self.inputWin)
    wrefresh(self.chatWin)
    wrefresh(self.inputWin)

  trace "TUI drew initial screen"

proc initScreen*(): (string, PWindow, bool) =
  # initialize ncurses
  let
    locale = $setlocale(LC_ALL, "")
    mainWin = initscr()

  refresh()

  # in raw mode, the interrupt, quit, suspend, and flow control characters are
  # all passed through uninterpreted, instead of generating a signal
  raw()
  # achieve similar efffect as `halfdelay(1)`, i.e. getch() will return -1
  # after 100 milliseconds if no input was supplied
  timeout(100)

  mousemask(ALL_MOUSE_EVENTS.mmask_t, nil)
  let mouse = hasmouse()

  colors()
  keypad(mainWin, true)
  noecho()
  setescdelay(0)

  trace "TUI set the locale", locale
  trace "TUI initialized ncurses"
  trace "TUI determined mouse support", mouse

  (locale, mainWin, mouse)

proc printInput*(self: ChatTUI, input: string) =
  wprintw(self.inputWin, input)
  wrefresh(self.inputWin)

  trace "TUI printed in input window"

proc printMessage*(self: ChatTUI, message: string, timestamp: int64,
  username: string) =

  let tstamp = timestamp.fromUnix().local().format("'<'MMM' 'dd,' 'HH:mm'>'")
  wprintw(self.chatWin, "\n" & tstamp & " " & username & ": " & message)
  wrefresh(self.chatWin)

  # move cursor to input window and refresh
  wcursyncup(self.inputWin)
  wrefresh(self.inputWin)

  trace "TUI printed in message window"

proc resizeScreen*(self: ChatTUI) =
  # end current windows
  endwin()
  refresh()
  clear()
  refresh()

  if LINES < 24 or COLS < 76:
    self.drawTermTooSmall()
  else:
    # redraw windows
    self.drawChatWin()
    self.drawInputWin()
    self.drawInfoLines()

    # redraw ascii splash
    # asciiSplash()

    # move cursor to input window and refresh
    wcursyncup(self.inputWin)
    wrefresh(self.chatWin)
    wrefresh(self.inputWin)

  trace "TUI redrew screen"
