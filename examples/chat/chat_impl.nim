import # vendor libs
  os

import # chat libs
  ./config

export config

type ChatClient* = ref object
  config*: ChatClientConfig
  dataDir*: string

# ChatClient's purpose is to provide procs that wrap task invocation for
# sending a message, etc.

# `new` should instantiate a TaskRunner
proc new*(T: type ChatClient, config: ChatClientConfig): T =
  T(config: config, dataDir: absolutePath(expandTilde(config.dataDir)))

proc start*(client: ChatClient) =
  # before starting the client's task runner, should prep client to accept
  # events coming from the StatusObject
  createDir(client.dataDir)
  # start the client's task runner, which in turn starts the StatusObject on
  # another thread
  echo "client.config: " & $client.config
  echo "client.dataDir: " & $client.dataDir

proc stop*(client: ChatClient) =
  echo "stopping the client..."
