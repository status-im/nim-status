import # client modules
  ./tui/events

export events

logScope:
  topics = "tui"

# TUI: https://en.wikipedia.org/wiki/Text-based_user_interface

# This module's purpose is to start the client and initiate listening for
# events coming from the client and user

const input = "input"

# `type Tui` and `proc stop(self: Tui)` are defined in ./common to avoid
# circular dependency

proc new*(T: type Tui, clientConfig: ClientConfig): T =
  let
    (locale, mainWin, mouse) = initScreen()
    client = Client.new(clientConfig)

  var taskRunner = TaskRunner.new()
  taskRunner.createWorker(thread, input)

  T(clientConfig: clientConfig, client: client, currentInput: "",
    events: newEventChannel(), inputReady: false, locale: locale,
    mainWin: mainWin, mouse: mouse, running: false, taskRunner: taskRunner)

proc start*(self: Tui) {.async.} =
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
