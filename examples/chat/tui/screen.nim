import # chat libs
  ./common

proc drawScreen*(self: ChatTUI) =
  discard printw("TUI is ready for input:\n\n")
  if self.currentInput != "": discard printw(self.currentInput)
  discard refresh()
