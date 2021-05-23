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

proc new*(T: type ChatTUI, dataDir: string): T =
  let
    (locale, mainWindow) = initScreen()
    client = ChatClient.new(dataDir)

  var taskRunner = TaskRunner.new()
  taskRunner.createWorker(thread, input)

  T(client: client, currentInput: "", dataDir: dataDir,
    events: newEventChannel(), inputReady: false, locale: locale,
    mainWindow: mainWindow, running: false, taskRunner: taskRunner)

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
