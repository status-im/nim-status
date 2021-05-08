import # chat libs
  ./client/tasks

export tasks

logScope:
  topics = "chat"

# This module's purpose is to provide procs that wrap task invocation to
# e.g. send a message via nim-status/waku running in a separate thread;
# starting the client also initiates listening for events coming from
# nim-status/waku

proc new*(T: type ChatClient, dataDir: string): T =
  var taskRunner = TaskRunner.new()
  taskRunner.createWorker(thread, "nim-status")
  taskRunner.createWorker(pool, "pool1", size = 4)
  taskRunner.createWorker(thread, "context-experiment", hello2Context)
  taskRunner.createWorker(pool, "counter", hello4Context)

  T(dataDir: dataDir, events: newEventChannel(), running: false,
    taskRunner: taskRunner)

proc play(self: ChatClient) {.async.} =
  # task playground ------------------------------------------------------------
  helloTask(self.taskRunner, "nim-status", "foo")
  helloTask(self.taskRunner, "pool1", "bar")

  hello2Task(self.taskRunner, "context-experiment")

  echo await hello3Task(self.taskRunner, "nim-status", "quux1-worker")
  echo await hello3Task(self.taskRunner, "pool1", "quux1-pool")
  echo hello3TaskSync(self.taskRunner, "nim-status", "quux2-worker")
  echo hello3TaskSync(self.taskRunner, "pool1", "quux2-pool")

  hello4Task(self.taskRunner, "counter")
  # ----------------------------------------------------------------------------

proc start*(self: ChatClient) {.async.} =
  debug "client starting"
  self.events.open()
  await self.taskRunner.start()
  debug "client started"
  # set `self.running = true` before any `asyncSpawn` so client logic can check
  # `self.running` to know whether to run / continue running / stop running
  self.running = true
  asyncSpawn self.listen()
  asyncSpawn self.play()

proc stop*(self: ChatClient) {.async.} =
  debug "client stopping"
  self.running = false
  await self.taskRunner.stop()
  self.events.close()
  debug "client stopped"
