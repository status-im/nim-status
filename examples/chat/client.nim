import # std libs
  os

import # vendor libs
  chronicles

import # chat libs
  ./client/tasks, ./config, ./task_runner

export config, task_runner

logScope:
  topics = "client"

type ChatClient* = ref object
  config*: ChatClientConfig
  dataDir*: string
  tasks*: TaskRunner

# ChatClient's purpose is to provide procs that wrap task invocation for
# sending a message, etc.

proc new*(T: type ChatClient, config: ChatClientConfig): T =
  var tasks = TaskRunner.new()
  tasks.worker(pool, "pool1")
  tasks.worker(pool, "pool2", emptyContext, 4)
  tasks.worker(pool, "pool3")
  T(config: config, dataDir: absolutePath(expandTilde(config.dataDir)),
    tasks: tasks)

proc start*(self: ChatClient) =
  trace "starting client"
  # before starting the client's task runner, should prep client to accept
  # events coming from the StatusObject
  createDir(self.dataDir)
  # start the client's task runner, which in turn starts the StatusObject on
  # another thread
  self.tasks.start()

proc stop*(self: ChatClient) =
  trace "stopping client"
  self.tasks.stop()
