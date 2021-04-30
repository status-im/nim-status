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
  let dataDir = handleConfig(ChatConfig.load())

  notice "start program"

  var tui = ChatTUI.new(ChatClient.new(dataDir), dataDir)
  var tuiPtr {.threadvar.}: pointer
  tuiPtr = cast[pointer](tui)

  proc stop() {.noconv.} = waitFor cast[ChatTUI](tuiPtr).stop()
  setControlCHook(stop)

  await tui.start()
  while tui.running: poll()

  notice "exit program"

when isMainModule: waitFor main()
