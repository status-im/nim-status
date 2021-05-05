import # vendor libs
  chronicles, chronos

import # chat libs
  ./client, ./task_runner, ./tui/tasks

export task_runner

logScope:
  topics = "chat"

# TUI: https://en.wikipedia.org/wiki/Text-based_user_interface

type ChatTUI* = ref object
  client*: ChatClient
  dataDir*: string
  running*: bool
  taskRunner*: TaskRunner

# ChatTUI's purpose is to dispatch on event type to appropriate proc/s, which
# will mainly involve printing messages in events from the client and taking
# action/s based on user events, e.g. calling a client proc to send a message
# or displaying a list of possible commands when user enters `/help` or `/?`

proc new*(T: type ChatTUI, client: ChatClient, dataDir: string): T =
  var taskRunner = TaskRunner.new()
  taskRunner.createWorker(thread, "input")
  T(client: client, dataDir: dataDir, running: true, taskRunner: taskRunner)

proc start*(self: ChatTUI) {.async.} =
  debug "TUI starting"
  # ... setup self.events channel (in constructor), open it here

  await self.taskRunner.start()
  # before starting the client or tui's task runner, should prep tui to accept
  # events coming from the client and user

  # IMPL (for above comments): now that taskRunner is started, in an
  # `asyncSpawn` listen for messages from it and send them to self.events
  # channel (happens on same thread so no need for serialization/copy-to-shared-heap)
  await self.client.start()
  debug "TUI started"

proc stop*(self: ChatTUI) {.async.} =
  debug "TUI stopping"
  await self.client.stop()
  await self.taskRunner.stop()
  self.running = false
  debug "TUI stopped"
