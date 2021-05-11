import # std libs
  strutils

import # chat libs
  ./common, ./tasks

export common, tasks

# TUI Event types are defined in ./common because `dispatch` et al. in this
# module and the procs in ./tasks make use of them

# NOTE: depending on the OS and/or terminal and related software, there can be
# a problem with how ncurses displays some emojis and other characters,
# e.g. those that make use of ZWJ or ZWNJ; there's not much that can be done
# about it at the present time:
# * https://stackoverflow.com/a/23533623
# * https://stackoverflow.com/a/54993513
# * https://en.wikipedia.org/wiki/Zero-width_joiner
# * https://en.wikipedia.org/wiki/Zero-width_non-joiner

logScope:
  topics = "chat"

const ESCAPE = "\u0027"

proc dispatch(self: ChatTUI, eventEnc: string) {.gcsafe, nimcall.}

proc listenToClient(self: ChatTUI) {.async.} =
  while self.client.running and self.running:
    let event = await self.client.events.recv()
    asyncSpawn self.events.send(event)

proc listenToInput(self: ChatTUI) {.async.} =
  let worker = self.taskRunner.workers["input"].worker
  while self.running and self.taskRunner.running.load():
    let event = await worker.chanRecvFromWorker.recv()
    asyncSpawn self.events.send(event)

proc listen*(self: ChatTUI) {.async.} =
  asyncSpawn self.listenToClient()
  asyncSpawn self.listenToInput()
  while self.running:
    let event = $(await self.events.recv())
    debug "TUI received event", event
    self.dispatch(event)

proc dispatch(self: ChatTUI, eventEnc: string) {.gcsafe, nimcall.} =
  var eventType: string
  try:
    eventType = parseJson(eventEnc){"$type"}.getStr().split(':')[0]
  except:
    eventType = ""

  # simple plan at first, could get more exotic e.g. handling shift+return,
  # handling "shortcut" like Ctrl-L for redrawing the scree, etc.

  # handle enter/return and check if it's a "command string", and if so run
  # the corresponding proc or report that it's an unknown command; if it's
  # not a command string then it's a message to send or information needed
  # to run the command so handle accordingly; finally clear the input area

  # if it's not enter/return then append to the input area

  case eventType:
    of "InputKeyEvent":
      # handle special keys e.g. arrow keys, F1, et al.
      discard

    of "InputStringEvent":
      let
        event = decode[InputStringEvent](eventEnc)

      var
        inputString = event.str
        shouldPrint = true

      case inputString:
        of ESCAPE:
          shouldPrint = false

        else:
          self.currentInput = self.currentInput & inputString

      trace "TUI currentInput", currentInput=self.currentInput

      if shouldPrint:
        discard printw(inputString)
        discard refresh()

    else:
      error "TUI received unknown event type", event=eventEnc


# Below is code that was part of a failed attempt to fix the emoji display
# problem (see note at to of of this module); my theory was that if a complete
# redraw of the line is forced then maybe it would render correctly. The code
# is kept around for the time being as a reference re: how to do some things,
# since learning ncurses is a WIP.

# const
#   ZWJ = "\u200D" # https://en.wikipedia.org/wiki/Zero-width_joiner
#   ZWNJ = "\u200C" # https://en.wikipedia.org/wiki/Zero-width_non-joiner
#
# if self.currentInput.contains(ZWJ) or
#    self.currentInput.contains(ZWNJ):
#   inputString = self.currentInput & inputString
#   self.currentInput = inputString
#   var
#     y: cint
#     x: cint
#   getyx(self.mainWindow, y, x)
#   discard move(y, 0)
#   discard clrtoeol()
