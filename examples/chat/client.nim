import # vendor libs
  chronicles, chronos

import # chat libs
  ./client/tasks, ./task_runner

export task_runner

logScope:
  topics = "chat"

type ChatClient* = ref object
  dataDir*: string
  taskRunner*: TaskRunner

# ChatClient's purpose is to provide procs that wrap task invocation for
# sending a message, etc. via nim-status/waku running in separate thread

proc new*(T: type ChatClient, dataDir: string): T =
  var taskRunner = TaskRunner.new()
  taskRunner.createWorker(thread, "nim-status")
  # taskRunner.createWorker(pool, "pool1")
  taskRunner.createWorker(pool, "pool2", emptyContext, ContextArg(), 4)
  # taskRunner.createWorker(pool, "pool3")
  taskRunner.createWorker(thread, "context-experiment", experimentalContext)
  T(dataDir: dataDir, taskRunner: taskRunner)

proc start*(self: ChatClient) {.async.} =
  debug "client starting"
  # ... setup self.events channel (in constructor), open it here

  await self.taskRunner.start()
  # before starting the client's task runner, should prep client to accept
  # events coming from the nim-status/waku

  # IMPL (for above comments): now that taskRunner is started, in an
  # `asyncSpawn` listen for messages from it and send them to self.events
  # channel (happens on same thread so no need for serialization/copy-to-shared-heap)
  debug "client started"

  # task playground ------------------------------------------------------------

  helloTask(self.taskRunner, "nim-status", "foo")
  helloTask(self.taskRunner, "pool2", "bar")

  # when `createTask` template/macro is implemented, would prefer to write
  # something like...

  # helloTask(self.taskRunner, "nim-status")("foo")

  # NOTE: `helloTask` would likely be a helper template that wraps `createTask`

  hello2Task(self.taskRunner, "context-experiment")

proc stop*(self: ChatClient) {.async.} =
  debug "client stopping"
  await self.taskRunner.stop()
  debug "client stopped"
