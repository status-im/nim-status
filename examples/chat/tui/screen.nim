import # chat libs
  ./common

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

proc drawScreen*(self: ChatTUI) =
  discard printw("TUI is ready for input:\n\n")
  if self.currentInput != "": discard printw(self.currentInput)
  discard refresh()
