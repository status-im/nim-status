import # chat libs
  ../client, ./ncurses_helpers

export client, ncurses_helpers

type
  ChatTUI* = ref object
    client*: ChatClient
    currentInput*: string
    dataDir*: string
    events*: EventChannel
    inputReady*: bool
    locale*: string
    mainWindow*: PWindow
    running*: bool
    taskRunner*: TaskRunner

  TUIEvent* = ref object of Event
  InputKey* = ref object of TUIEvent
    key*: int
    name*: string
  InputReady* = ref object of TUIEvent
    ready*: bool
  InputString* = ref object of TUIEvent
    str*: string

  Command* = ref object of RootObj
  # all fields on types that derive from Command should be of type `string`
  Help* = ref object of Command
    command*: string
  Login* = ref object of Command
    username*: string
    password*: string
  Logout* = ref object of Command
  Quit* = ref object of Command
  SendMessage* = ref object of Command
    message*: string

const
  TUIEvents* = [
    "InputKey",
    "InputReady",
    "InputString"
  ]

  DEFAULT_COMMAND* = ""

  commands* = {
    DEFAULT_COMMAND: "SendMessage",
    "help": "Help",
    "login": "Login",
    "logout": "Logout",
    "quit": "Quit"
  }.toTable

  aliases* = {
    "?": "help",
    "send": DEFAULT_COMMAND
  }.toTable

  aliased* = {
    DEFAULT_COMMAND: @["send"],
    "help": @["?"]
  }.toTable

proc stop*(self: ChatTUI) {.async.} =
  debug "TUI stopping"

  var stopping: seq[Future[void]] = @[]
  stopping.add self.client.stop()
  stopping.add self.taskRunner.stop()
  await allFutures(stopping)
  self.events.close()

  discard endwin()
  trace "TUI restored the terminal"

  debug "TUI stopped"
  # set `self.running = true` as the the last step to facilitate clean program
  # exit (see ../chat)
  self.running = false
