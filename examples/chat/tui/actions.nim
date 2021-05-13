import # std libs
  strutils

import # chat libs
  ./commands

export commands, strutils

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

type
  Action* = proc(self: ChatTUI, event: Event): Future[void] {.gcsafe, nimcall.}

# Action and Command (see: ./commands) procs are `{.async.}` for the
# convenience of e.g. interaction with channels and tasks. However, they should
# be self-contained with respect to their effects (with allowance for
# `await`-ing or `waitFor`-ing invocation of another `{.async.}` proc or
# blocking until return of a synchronous proc), i.e. other than invoking tasks
# (to do work on other threads) or sending to a channel (using `asyncSpawn`),
# they *should not* spawn independent asynchronous routines to cause side
# effects in the main thread that would happen *after* the current
# action/command has returned. They should also return as soon as possible and
# should be considered to effectively "block the main thread" while they are
# executing. The time budget for an action/command is 16 milliseconds so as to
# maintain at least 60 FPS in the TUI.

const processKey*: Action = proc(self: ChatTUI, event: Event) {.async, gcsafe, nimcall.} =
  # handle special keys e.g. arrow keys, ESCAPE, F1, RETURN, et al.
  let
    event = cast[InputKey](event)
    key = event.key
    name = event.name

  case name:
    of ESCAPE:
      discard

    of RETURN:
        var x, y: cint
        getyx(self.mainWindow, y, x)
        discard move(y, 0)
        discard clrtoeol()
        discard refresh()

        self.dispatchCommand(self.currentInput)

        self.currentInput = ""
        trace "TUI reset current input", currentInput=self.currentInput

    else:
      discard

const processInput*: Action = proc(self: ChatTUI, event: Event) {.async, gcsafe, nimcall.} =
  let
    event = cast[InputString](event)
    input = event.str
    shouldPrint = if not self.inputReady: false else: true

  self.currentInput = self.currentInput & input
  trace "TUI updated current input", currentInput=self.currentInput

  if shouldPrint:
    discard printw(input)
    discard refresh()

const processReady*: Action = proc(self: ChatTUI, event: Event) {.async, gcsafe, nimcall.} =
  let
    event = cast[InputReady](event)
    ready = event.ready

  if ready:
    self.inputReady = true
    self.drawScreen()

proc dispatchEvent*(self: ChatTUI, eventEnc: string) {.gcsafe, nimcall.} =
  var eventType: string
  try:
    eventType = parseJson(eventEnc){"$type"}.getStr().split(':')[0]
  except:
    eventType = ""

  case eventType:
    of "InputKey":
      discard
      waitFor self.processKey(decode[InputKey](eventEnc))

    of "InputReady":
      waitFor self.processReady(decode[InputReady](eventEnc))

    of "InputString":
      waitFor self.processInput(decode[InputString](eventEnc))

    else:
      error "TUI received unknown event type", event=eventEnc
