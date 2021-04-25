import # vendor libs
  os

import # chat libs
  ./config

export config

type ChatClient* = ref object
  config*: ChatClientConfig
  dataDir*: string

# `new` should instantiate Task Runner, which in turn instantiates/starts the
# StatusObject, etc. on other threads
proc new*(T: type ChatClient, config: ChatClientConfig): T =
  T(config: config, dataDir: absolutePath(expandTilde(config.dataDir)))

proc start*(client: ChatClient) =
  createDir(client.dataDir)
