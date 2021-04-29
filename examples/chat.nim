## chat is an example program demonstrating usage of nim-status

when not(compileOption("threads")):
  {.fatal: "Please compile this program with the --threads:on option!".}

import # std libs
  os

import # vendor libs
  chronicles, chronos

import # chat libs
  ./chat/[client, config, tui]

logScope:
  topics = "chat"

proc main() {.async.} =
  let config = ChatConfig.load()
  let dataDir = absolutePath(expandTilde(config.dataDir))
  let logFile =
    if config.dataDir != defaultDataDir() and config.logFile == defaultLogFile():
      joinPath(dataDir, extractFilename(defaultLogFile()))
    else:
      absolutePath(expandTilde(config.logFile))

  createDir(dataDir)
  discard defaultChroniclesStream.output.open(logFile, fmAppend)

  notice "START PROGRAM"
  var tui = ChatTUI.new(ChatClient.new(dataDir), dataDir)
  var tuiPtr {.threadvar.}: pointer
  tuiPtr = cast[pointer](tui)

  proc stop() {.noconv.} = cast[ChatTUI](tuiPtr).stop()
  setControlCHook(stop)

  tui.start()
  while tui.running: poll()
  notice "EXIT PROGRAM"

when isMainModule: waitFor(main())
