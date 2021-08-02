# std libs
from times import fromUnix, inZone, local

import # client modules
  ./common

logScope:
  topics = "tui"

# CREDIT: the structure of this module was inspired by TBDChat
# https://github.com/mgeitz/tbdchat

proc asciiSplash*(self: Tui) =
  # TODO
  # there are tools online for making decent looking "ASCII banners", e.g.
  # * https://patorjk.com/software/taag/#p=display&f=Graffiti&t=status
  # * https://manytools.org/hacker-tools/ascii-banner/
  discard

# replace `clearInput` with adaptations of ncurses calls in TBDChat
proc clearInput*(self: Tui) =
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

proc deleteBackward*(self: Tui) =
  let inputLen = self.currentInput.len
  if inputLen > 0:
    # when cursor is able to be moved with arrow keys, modifying
    # self.currentInput needs to take into account current cursor
    # position and geometry of self.inputWin
    self.currentInput.setLen(inputLen - 1)

    # adapted from: https://stackoverflow.com/a/55148654

    let inputWin = self.inputWin
    var y, x: cint
    getyx(inputWin, y, x)

    if x == 0.cint:
      if y == 0.cint:
        return

      x = getmaxx(inputWin)
      y = y - 1.cint
      wmove(inputWin, y, x)

      var ch = ' '.chtype
      while ch == ' '.chtype and x != 0.cint:
        x = x - 1.cint
        wmove(inputWin, y, x)
        ch = winch(inputWin)

    else:
      wmove(inputWin, y, x - 1.cint)

    wdelch(inputWin)
    wrefresh(inputWin)

    trace "TUI backward-deleted in input window"

proc deleteForward*(self: Tui) =
  # implement when cursor is able to be moved with arrow keys; modifying
  # self.currentInput and forward-deleting a char in self.inputWin needs
  # to take into account current cursor position and geometry of
  # self.inputWin

  # trace "TUI forward-deleted in input window"

  warn "TUI has no implementation for forward-deletion"

proc drawOutputWin*(self: Tui) =
  # create subwindow for output box
  self.outputWinBox = subwin(self.mainWin, (LINES.float64 * 0.8).cint, COLS, 0, 0)
  box(self.outputWinBox, 0, 0)

  # add title to subwindow
  mvwaddch(self.outputWinBox, 0, ((COLS.float64 * 0.5).int - 10).cint, ACS_RTEE)
  wattron(self.outputWinBox, COLOR_PAIR(3).cint)
  mvwaddstr(self.outputWinBox, 0, ((COLS.float64 * 0.5).int - 9).cint,
    " nim-status client ")
  wattroff(self.outputWinBox, COLOR_PAIR(3).cint)
  mvwaddch(self.outputWinBox, 0, ((COLS.float64 * 0.5).int + 10).cint, ACS_LTEE)

  # draw subwindow
  wrefresh(self.outputWinBox)

  # create sub-subwindow to hold text
  self.outputWin = subwin(self.outputWinBox, ((LINES.float64 * 0.8).int - 2).cint,
    COLS - 2, 1, 1)

  # enable text scrolling
  scrollok(self.outputWin, true)

proc drawInfoLines*(self: Tui) =
  # create info line above input window
  self.infoLine = subwin(self.mainWin, 1, COLS, (LINES.float64 * 0.8).cint, 0)

  # write initial text to info line
  wbkgd(self.infoLine, COLOR_PAIR(3).chtype)
  wprintw(self.infoLine, " Type /help to view a list of available commands")
  wrefresh(self.infoLine)

  # create lower info line
  self.infoLineBottom = subwin(self.mainWin, 1, COLS, LINES - 1, 0)

proc drawInputWin*(self: Tui) =
  # create subwindow for the input box
  self.inputWinBox = subwin(self.mainWin, ((LINES.float64 * 0.2).int - 1).cint,
    COLS, ((LINES.float64 * 0.8).int + 1).cint, 0)
  box(self.inputWinBox, 0, 0)

  # draw subwindow
  wrefresh(self.inputWinBox)

  # create sub subwindow to hold input text
  self.inputWin = subwin(self.inputWinBox, ((LINES.float64 * 0.2).int - 3).cint,
    COLS - 2, ((LINES.float64 * 0.8).int + 2).cint, 1)

proc drawTermTooSmall*(self: Tui) =
  wbkgd(self.mainWin, COLOR_PAIR(8).chtype)
  wattron(self.mainWin, A_BOLD.cint)
  mvwaddstr(self.mainWin, ((LINES.float64 * 0.5).int - 1).cint,
    ((COLS.float64 * 0.5).int - 3).cint, "TERMINAL")
  mvwaddstr(self.mainWin, (LINES.float64 * 0.5).cint,
    ((COLS.float64 * 0.5).int - 4).cint, "TOO SMALL!")
  wattroff(self.mainWin, A_BOLD.cint)
  wrefresh(self.mainWin)
  wbkgd(self.mainWin, COLOR_PAIR(1).chtype)

proc drawScreen*(self: Tui, redraw = false) =
  if LINES < 24 or COLS < 76:
    self.drawTermTooSmall()
  else:
    self.drawOutputWin()
    self.drawInputWin()
    self.drawInfoLines()
    self.asciiSplash()

    # move cursor to input window and refresh
    wcursyncup(self.inputWin)
    wrefresh(self.outputWin)
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
proc printInput*(self: Tui, input: string) =
  wprintw(self.inputWin, input)
  wrefresh(self.inputWin)

  trace "TUI printed in input window"

proc resizeScreen*(self: Tui) =
  # end current windows
  endwin()
  refresh()
  clear()

  # redraw the screen
  self.drawScreen(true)

proc wprintFormat(self: Tui, win: PWindow, timestamp: int64, origin: string, text: string,
  originColor: int) =

  discard

proc wprintFormatMessage(self: Tui, win: PWindow, timestamp: int64, origin: string,
  text: string, originColor: int) =

  discard

proc wprintFormatmotd(self: Tui, win: PWindow, timestamp: int64, motd: string) =
  discard

proc wprintWhoseLineIsItAnyways(self: Tui, win: PWindow, timestamp: int64, user: string,
  realname: string, realnameColor: int) =

  discard

proc wprintFormatTime*(self: Tui, timestamp: int64) =
  let
    win = self.outputWin

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

proc wprintFormatError*(self: Tui, timestamp: int64, error: string) =
  let
    outputWin = self.outputWin
    inputWin = self.inputWin

  # print formatted time
  self.wprintFormatTime(timestamp)

  # error message formatting
  wattron(outputWin, A_BOLD.cint)
  wprintw(outputWin, " ")
  waddch(outputWin, ACS_HLINE)
  waddch(outputWin, ACS_HLINE)
  waddch(outputWin, ACS_HLINE)
  wprintw(outputWin, " ")
  wattron(outputWin, COLOR_PAIR(8).cint)
  wprintw(outputWin, "Error")
  wattroff(outputWin, COLOR_PAIR(8).cint)
  wattroff(outputWin, A_BOLD.cint)

  # print error message
  wattron(outputWin, COLOR_PAIR(1).cint)
  wprintw(outputWin, fmt(" {error}\n"))
  wattroff(outputWin, COLOR_PAIR(1).cint)

  # move cursor to input window and refresh
  wcursyncup(inputWin)
  wrefresh(outputWin)
  wrefresh(inputWin)

  warn "TUI printed error message", message=error

proc printMessage*(self: Tui, message: string, timestamp: int64,
  username: string, topic: string) =

  let
    outputWin = self.outputWin
    inputWin = self.inputWin

  # print formatted time
  self.wprintFormatTime(timestamp)

  # print result
  wattron(outputWin, COLOR_PAIR(3).cint)
  wprintw(outputWin, fmt("[{topic}]"))
  wattroff(outputWin, COLOR_PAIR(3).cint)
  wattron(outputWin, COLOR_PAIR(2).cint)
  wprintw(outputWin, fmt(" {username}"))
  wattroff(outputWin, COLOR_PAIR(2).cint)
  wattron(outputWin, COLOR_PAIR(1).cint)
  wprintw(outputWin, fmt(": {message}\n"))
  wattroff(outputWin, COLOR_PAIR(1).cint)

  # move cursor to input window and refresh
  wcursyncup(inputWin)
  wrefresh(outputWin)
  wrefresh(inputWin)

  trace "TUI printed in message window", message

proc printResult*(self: Tui, message: string, timestamp: int64) =
  let
    outputWin = self.outputWin
    inputWin = self.inputWin

  # print formatted time
  self.wprintFormatTime(timestamp)

  # print result
  wattron(outputWin, COLOR_PAIR(1).cint)
  wprintw(outputWin, fmt("{message}\n"))
  wattroff(outputWin, COLOR_PAIR(1).cint)

  # move cursor to input window and refresh
  wcursyncup(inputWin)
  wrefresh(outputWin)
  wrefresh(inputWin)

  trace "TUI printed in message window", message

proc wprintFormatNotice(self: Tui, win: PWindow, timestamp: int64, notice: string) =
  discard

proc wprintSeperatorTitle(self: Tui, win: PWindow, title: string, color: int,
  titleColor: int) =

  discard

proc wprintSeperator(self: Tui, win: PWindow, color: int) =
  discard
