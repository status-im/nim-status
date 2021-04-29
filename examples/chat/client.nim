import # vendor libs
  chronicles

import # chat libs
  ./client/tasks, ./task_runner

export task_runner

logScope:
  topics = "client"

type ChatClient* = ref object
  dataDir*: string
  tasks*: TaskRunner

# ChatClient's purpose is to provide procs that wrap task invocation for
# sending a message, etc. via nim-status/waku running in separate thread

proc new*(T: type ChatClient, dataDir: string): T =
  var tasks = TaskRunner.new()
  tasks.createWorker(pool, "pool1")
  tasks.createWorker(pool, "pool2", emptyContext, 4)
  tasks.createWorker(pool, "pool3")
  T(dataDir: dataDir, tasks: tasks)

proc start*(self: ChatClient) =
  trace "starting client"
  # before starting the client's task runner, should prep client to accept
  # events coming from the nim-status/waku
  # start the client's task runner, which in turn starts nim-status/waku on
  # another thread
  self.tasks.start()

proc stop*(self: ChatClient) =
  trace "stopping client"
  self.tasks.stop()
