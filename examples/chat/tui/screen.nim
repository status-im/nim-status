import # chat libs
  ./common

export common

logScope:
  topics = "chat"

# NOTE: depending on the OS and/or terminal and related software, there can be
# a problem with how ncurses displays some emojis and other characters,
# e.g. those that make use of ZWJ or ZWNJ; there's not much that can be done
# about it at the present time:
# * https://stackoverflow.com/a/23533623
# * https://stackoverflow.com/a/54993513
# * https://en.wikipedia.org/wiki/Zero-width_joiner
# * https://en.wikipedia.org/wiki/Zero-width_non-joiner

proc clearInput*(self: ChatTUI) =
  var x, y: cint
  getyx(self.mainWindow, y, x)
  discard move(y, 0)
  discard clrtoeol()
  discard refresh()

  trace "TUI cleared input window"

proc drawScreen*(self: ChatTUI) =
  discard printw("TUI is ready for input:\n\n")
  if self.currentInput != "": discard printw(self.currentInput)
  discard refresh()

  trace "TUI drew initial screen"

proc initScreen*(): (string, PWindow) =
  # initialize ncurses
  let
    locale = $setlocale(LC_ALL, "")
    mainWindow = initscr()

  discard refresh()

  trace "TUI set the locale", locale
  trace "TUI initialized ncurses"

  result = (locale, mainWindow)

  # `halfdelay(N)` will cause ncurses' `getch()` (used in ./tui/tasks) to
  # return -1 after N tenths of a second if no input was supplied
  discard halfdelay(1)
  discard noecho()
  discard keypad(mainWindow, true)
  discard setescdelay(0)

proc printInput*(self: ChatTUI, input: string) =
  discard printw(input)
  discard refresh()

  trace "TUI printed in input window"
