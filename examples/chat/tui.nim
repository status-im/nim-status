import # chat libs
  ./tui/events

export events

logScope:
  topics = "chat"

# TUI: https://en.wikipedia.org/wiki/Text-based_user_interface

# This module's purpose is to start the client and initiate listening for
# events coming from the client and user

const input = "input"

# `proc stop(self: ChatTUI)` is defined in ./common to avoid circular dependency

proc new*(T: type ChatTUI, chatConfig: ChatConfig): T =
  let
    (locale, mainWin) = initScreen()
    client = ChatClient.new(chatConfig)

  var taskRunner = TaskRunner.new()
  taskRunner.createWorker(thread, input)

  T(chatConfig: chatConfig, client: client, currentInput: "",
    events: newEventChannel(), inputReady: false, locale: locale,
    mainWin: mainWin, running: false, taskRunner: taskRunner)

proc start*(self: ChatTUI) {.async.} =
  debug "TUI starting"

  self.events.open()
  var starting: seq[Future[void]] = @[]
  starting.add self.taskRunner.start()
  starting.add self.client.start()
  await allFutures(starting)

  # set `self.running = true` before any `asyncSpawn` so TUI logic can check
  # `self.running` to know whether to run / continue running / stop running
  self.running = true
  debug "TUI started"

  asyncSpawn self.listen()
  asyncSpawn readInput(self.taskRunner, input)
