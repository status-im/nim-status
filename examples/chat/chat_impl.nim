import # vendor libs
  os

import # chat libs
  ./config, ./tasks

export config, tasks

type ChatClient* = ref object
  config*: ChatClientConfig
  dataDir*: string
  tasks*: TaskRunner

# ChatClient's purpose is to provide procs that wrap task invocation for
# sending a message, etc.

proc new*(T: type ChatClient, config: ChatClientConfig): T =
  var tasks = TaskRunner.new()
  tasks.workers["pool1"] = (kind: pool, worker: WorkerPool.new(1))
  tasks.workers["pool2"] = (kind: pool, worker: WorkerPool.new(2, 4))
  tasks.workers["pool3"] = (kind: pool, worker: WorkerPool.new(3))
  T(config: config, dataDir: absolutePath(expandTilde(config.dataDir)),
    tasks: tasks)

proc start*(self: ChatClient) =
  echo "starting the client..."
  # before starting the client's task runner, should prep client to accept
  # events coming from the StatusObject
  createDir(self.dataDir)
  # start the client's task runner, which in turn starts the StatusObject on
  # another thread
  self.tasks.start()

proc stop*(self: ChatClient) =
  echo "stopping the client..."
  self.tasks.stop()
