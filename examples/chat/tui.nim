import # chat libs
  ./tui/events

export events

logScope:
  topics = "chat"

# TUI: https://en.wikipedia.org/wiki/Text-based_user_interface

# This module's purpose is to start the client and initiate listening for
# events coming from the client and user

const input = "input"

proc new*(T: type ChatTUI, client: ChatClient, dataDir: string): T =
  let locale = $setlocale(LC_ALL, "")
  trace "TUI set the locale", locale

  # initialize ncurses
  let mainWindow = initscr()

  # `halfdelay(N)` will cause ncurses' `getch()` (used in ./tui/tasks) to
  # return -1 after N tenths of a second if no input was supplied
  discard halfdelay(1)
  discard noecho()
  discard keypad(mainWindow, true)
  discard setescdelay(0)
  trace "TUI initialized ncurses"

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

  debug "TUI started"

  # set `self.running = true` before any `asyncSpawn` so TUI logic can check
  # `self.running` to know whether to run / continue running / stop running
  self.running = true
  asyncSpawn self.listen()
  asyncSpawn readInput(self.taskRunner, input)

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
