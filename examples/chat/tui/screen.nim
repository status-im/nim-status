import # std libs
  std/[strformat, strutils]

import # chat libs
  ./common

export common

logScope:
  topics = "chat tui"

# CREDIT: the structure of this module was inspired by TBDChat
# https://github.com/mgeitz/tbdchat

proc asciiSplash*(self: ChatTUI) =
  # TODO
  # there are tools online for making decent looking "ASCII banners", e.g.
  # * https://patorjk.com/software/taag/#p=display&f=Graffiti&t=status
  # * https://manytools.org/hacker-tools/ascii-banner/
  discard

# replace `clearInput` with adaptations of ncurses calls in TBDChat
proc clearInput*(self: ChatTUI) =
  var x, y: cint
  wmove(self.inputWin, 0, 0)
  wclear(self.inputWin)
  wrefresh(self.inputWin)

  trace "TUI cleared input window"

proc colors() =
  # TUI is using colors
  start_color()
  # use default terminal colors
  use_default_colors()

  # initialize color pairs
  init_pair(1, -1, -1) # default
  init_pair(2, COLOR_CYAN, -1)
  init_pair(3, COLOR_YELLOW, -1)
  init_pair(4, COLOR_RED, -1)
  init_pair(5, COLOR_BLUE, -1)
  init_pair(6, COLOR_MAGENTA, -1)
  init_pair(7, COLOR_GREEN, -1)
  init_pair(8, COLOR_WHITE, COLOR_RED)

proc drawChatWin*(self: ChatTUI) =
  # create subwindow for chat box
  self.chatWinBox = subwin(self.mainWin, (LINES.float64 * 0.8).cint, COLS, 0, 0)
  box(self.chatWinBox, 0, 0)

  # add title to subwindow
  mvwaddch(self.chatWinBox, 0, ((COLS.float64 * 0.5).int - 9).cint, ACS_RTEE)
  wattron(self.chatWinBox, COLOR_PAIR(3).cint)
  mvwaddstr(self.chatWinBox, 0, ((COLS.float64 * 0.5).int - 8).cint,
    " nim-status chat ")
  wattroff(self.chatWinBox, COLOR_PAIR(3).cint)
  mvwaddch(self.chatWinBox, 0, ((COLS.float64 * 0.5).int + 9).cint, ACS_LTEE)

  # draw subwindow
  wrefresh(self.chatWinBox)

  # create sub-subwindow to hold text
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
  wbkgd(self.mainWin, COLOR_PAIR(8).chtype)
  wattron(self.mainWin, A_BOLD.cint)
  mvwaddstr(self.mainWin, ((LINES.float64 * 0.5).int - 1).cint,
    ((COLS.float64 * 0.5).int - 3).cint, "TERMINAL")
  mvwaddstr(self.mainWin, (LINES.float64 * 0.5).cint,
    ((COLS.float64 * 0.5).int - 4).cint, "TOO SMALL!")
  wattroff(self.mainWin, A_BOLD.cint)
  wrefresh(self.mainWin)
  wbkgd(self.mainWin, COLOR_PAIR(1).chtype)

proc drawScreen*(self: ChatTUI, redraw = false) =
  if LINES < 24 or COLS < 76:
    self.drawTermTooSmall()
  else:
    self.drawChatWin()
    self.drawInputWin()
    self.drawInfoLines()
    self.asciiSplash()

    # move cursor to input window and refresh
    wcursyncup(self.inputWin)
    wrefresh(self.chatWin)
    wrefresh(self.inputWin)

  if redraw:
    trace "TUI redrew the screen"
  else:
    trace "TUI drew the initial screen"

proc indent*(spaces: int): string =
  " ".repeat(spaces)

proc initScreen*(): (string, PWindow, bool) =
  # initialize ncurses
  let
    locale = $setlocale(LC_ALL, "")
    mainWin = initscr()

  colors()
  refresh()

  # in raw mode, the interrupt, quit, suspend, and flow control characters are
  # all passed through uninterpreted, instead of generating a signal
  raw()
  # achieve similar efffect as ncurses' `halfdelay(1)`, i.e. `getch()` will
  # return `-1` after 100 milliseconds if no input was supplied
  timeout(100)

  mousemask(ALL_MOUSE_EVENTS.mmask_t, nil)
  let mouse = hasmouse()

  keypad(mainWin, true)
  noecho()
  setescdelay(0)

  trace "TUI set the locale", locale
  trace "TUI initialized ncurses"
  trace "TUI determined mouse support", mouse

  (locale, mainWin, mouse)

# replace `printInput` with adaptations of ncurses calls in TBDChat
proc printInput*(self: ChatTUI, input: string) =
  wprintw(self.inputWin, input)
  wrefresh(self.inputWin)

  trace "TUI printed in input window"

proc resizeScreen*(self: ChatTUI) =
  # end current windows
  endwin()
  refresh()
  clear()

  # redraw the screen
  self.drawScreen(true)

proc wprintFormat(self: ChatTUI, win: PWindow, timestamp: int64, origin: string, text: string,
  originColor: int) =

  discard

proc wprintFormatMessage(self: ChatTUI, win: PWindow, timestamp: int64, origin: string,
  text: string, originColor: int) =

  discard

proc wprintFormatmotd(self: ChatTUI, win: PWindow, timestamp: int64, motd: string) =
  discard

proc wprintWhoseLineIsItAnyways(self: ChatTUI, win: PWindow, timestamp: int64, user: string,
  realname: string, realnameColor: int) =

  discard

proc wprintFormatTime*(self: ChatTUI, timestamp: int64) =
  let
    win = self.chatWin

    localdatetime = inZone(fromUnix(timestamp), local())
    lhour = localdatetime.hour
    lminute = localdatetime.minute
    lsecond = localdatetime.second

  # print HH:MM:SS
  wattron(win, COLOR_PAIR(1).cint)
  wprintw(win, fmt("{lhour:02}"))
  wattroff(win, COLOR_PAIR(1).cint)
  wattron(win, COLOR_PAIR(3).cint)
  wprintw(win, ":")
  wattroff(win, COLOR_PAIR(3).cint)
  wattron(win, COLOR_PAIR(1).cint)
  wprintw(win, fmt("{lminute:02}"))
  wattroff(win, COLOR_PAIR(1).cint)
  wattron(win, COLOR_PAIR(3).cint)
  wprintw(win, ":")
  wattroff(win, COLOR_PAIR(3).cint)
  wattron(win, COLOR_PAIR(1).cint)
  wprintw(win, fmt("{lsecond:02}"))
  wattroff(win, COLOR_PAIR(1).cint)

  # print vertical line
  wattron(win, COLOR_PAIR(7).cint)
  wprintw(win, " ")
  waddch(win, ACS_VLINE)
  wprintw(win, " ")
  wattroff(win, COLOR_PAIR(7).cint)

proc wprintFormatError*(self: ChatTUI, timestamp: int64, error: string) =
  let
    chatWin = self.chatWin
    inputWin = self.inputWin

  # print formatted time
  self.wprintFormatTime(timestamp)

  # error message formatting
  wattron(chatWin, A_BOLD.cint)
  wprintw(chatWin, " ")
  waddch(chatWin, ACS_HLINE)
  waddch(chatWin, ACS_HLINE)
  waddch(chatWin, ACS_HLINE)
  wprintw(chatWin, " ")
  wattron(chatWin, COLOR_PAIR(8).cint)
  wprintw(chatWin, "Error")
  wattroff(chatWin, COLOR_PAIR(8).cint)
  wattroff(chatWin, A_BOLD.cint)

  # print error message
  wattron(chatWin, COLOR_PAIR(1).cint)
  wprintw(chatWin, fmt(" {error}\n"))
  wattroff(chatWin, COLOR_PAIR(1).cint)

  # move cursor to input window and refresh
  wcursyncup(inputWin)
  wrefresh(chatWin)
  wrefresh(inputWin)

  warn "TUI printed error message", message=error

proc printMessage*(self: ChatTUI, message: string, timestamp: int64,
  username: string, topic: string) =

  let
    chatWin = self.chatWin
    inputWin = self.inputWin

  # print formatted time
  self.wprintFormatTime(timestamp)

  # print result
  wattron(chatWin, COLOR_PAIR(3).cint)
  wprintw(chatWin, fmt("[{topic}]"))
  wattroff(chatWin, COLOR_PAIR(3).cint)
  wattron(chatWin, COLOR_PAIR(2).cint)
  wprintw(chatWin, fmt(" {username}"))
  wattroff(chatWin, COLOR_PAIR(2).cint)
  wattron(chatWin, COLOR_PAIR(1).cint)
  wprintw(chatWin, fmt(": {message}\n"))
  wattroff(chatWin, COLOR_PAIR(1).cint)

  # move cursor to input window and refresh
  wcursyncup(inputWin)
  wrefresh(chatWin)
  wrefresh(inputWin)

  trace "TUI printed in message window", message

proc printResult*(self: ChatTUI, message: string, timestamp: int64) =
  let
    chatWin = self.chatWin
    inputWin = self.inputWin

  # print formatted time
  self.wprintFormatTime(timestamp)

  # print result
  wattron(chatWin, COLOR_PAIR(1).cint)
  wprintw(chatWin, fmt("{message}\n"))
  wattroff(chatWin, COLOR_PAIR(1).cint)

  # move cursor to input window and refresh
  wcursyncup(inputWin)
  wrefresh(chatWin)
  wrefresh(inputWin)

  trace "TUI printed in message window", message

proc wprintFormatNotice(self: ChatTUI, win: PWindow, timestamp: int64, notice: string) =
  discard

proc wprintSeperatorTitle(self: ChatTUI, win: PWindow, title: string, color: int,
  titleColor: int) =

  discard

proc wprintSeperator(self: ChatTUI, win: PWindow, color: int) =
  discard
