import # std libs
  os

import # vendor libs
  chronicles, confutils

export chronicles, confutils, os

proc defaultDataDir*(): string =
  # logic here could evolve to something more complex (e.g. platform-specific)
  # like the `defaultDataDir()` of status-desktop
  joinPath(getCurrentDir(), "data")

proc defaultLogFile*(): string =
  joinPath(defaultDataDir(), "chat.log")

type ChatConfig* = object
  dataDir* {.
    abbr: "d"
    defaultValue: defaultDataDir()
    desc: "Chat data directory. Default is ${PWD}/data. If supplied path is " &
          "relative it will be resolved from ${PWD}"
  .}: string

  logFile* {.
    abbr: "l"
    defaultValue: defaultLogFile()
    desc: "Chat log file. Default is ./chat.log relative to --dataDir " &
          "(see above). If supplied path is relative it will be resolved " &
          "from ${PWD}"
  .}: string

proc handleConfig*(config: ChatConfig): string =
  let
    dataDir = absolutePath(expandTilde(config.dataDir))
    logFile =
      if config.dataDir != defaultDataDir() and
         config.logFile == defaultLogFile():
        joinPath(dataDir, extractFilename(defaultLogFile()))
      else:
        absolutePath(expandTilde(config.logFile))

  createDir(dataDir)
  discard defaultChroniclesStream.output.open(logFile, fmAppend)
  return dataDir
