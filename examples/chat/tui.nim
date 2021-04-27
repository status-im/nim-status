import # chat libs
  ./client, ./task_runner

export task_runner

# TUI: https://en.wikipedia.org/wiki/Text-based_user_interface

type ChatTUI* = ref object
  client*: ChatClient
  running*: bool
  tasks*: TaskRunner

# ChatTUI's job will be to dispatch on event type to appropriate proc/s, which
# will mainly involve printing messages in events from the client and taking
# action/s based on user events, e.g. calling a client proc to send a message
# or displaying a list of possible commands when user enters `/help` or `/?`

proc new*(T: type ChatTUI, client: ChatClient): T =
  var tasks = TaskRunner.new()
  tasks.workers["input"] = (kind: thread, worker: WorkerThread.new(1, "input"))
  T(client: client, running: true, tasks: tasks)

proc start*(self: ChatTUI) =
  echo "starting the TUI..."
  # before starting the client or tui's task runner, should prep tui to accept
  # events coming from the client and user
  echo "tui.client.config: " & $self.client.config
  echo "tui.client.dataDir: " & $self.client.dataDir
  # before starting the client, start tui's task runner, which in turn starts a
  # thread dedicated to monitoring user input/actions
  self.tasks.start()
  self.client.start()

proc stop*(self: ChatTUI) =
  echo "\n"
  self.client.stop()
  echo "stopping the TUI..."
  self.tasks.stop()
  self.running = false
