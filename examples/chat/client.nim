import # chat libs
  ./client/tasks

export tasks

logScope:
  topics = "chat"

# This module's purpose is to provide wrappers for task invocation to e.g. send
# a message via nim-status/waku running in a separate thread; starting the
# client also initiates listening for events coming from nim-status/waku.

const status = "status"

proc new*(T: type ChatClient, dataDir: string): T =
  var taskRunner = TaskRunner.new()
  taskRunner.createWorker(thread, status)

  T(dataDir: dataDir, events: newEventChannel(), running: false,
    taskRunner: taskRunner)

proc start*(self: ChatClient) {.async.} =
  debug "client starting"
  self.events.open()
  await self.taskRunner.start()
  debug "client started"
  # set `self.running = true` before any `asyncSpawn` so client logic can check
  # `self.running` to know whether to run / continue running / stop running
  self.running = true
  asyncSpawn self.listen()

proc stop*(self: ChatClient) {.async.} =
  debug "client stopping"
  self.running = false
  await self.taskRunner.stop()
  self.events.close()
  debug "client stopped"
