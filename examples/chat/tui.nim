import # vendor libs
  chronicles

import # chat libs
  ./client, ./task_runner, ./tui/tasks

export task_runner

logScope:
  topics = "TUI"

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
  trace "starting TUI"
  # before starting the client or tui's task runner, should prep tui to accept
  # events coming from the client and user
  # before starting the client, start tui's task runner, which in turn starts a
  # thread dedicated to monitoring user input/actions
  await self.taskRunner.start()
  await self.client.start()

proc stop*(self: ChatTUI) {.async.} =
  await self.client.stop()
  trace "stopping TUI"
  await self.taskRunner.stop()
  self.running = false
