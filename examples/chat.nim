## chat.nim is an example program demonstrating usage of nim-status,
## nim-task-runner, and nim-ncurses

when not(compileOption("threads")):
  {.fatal: "Please compile this program with the --threads:on option!".}

import # chat libs
  ./chat/[config, tui]

logScope:
  topics = "chat"

proc main() {.async.} =
  let dataDir = handleConfig(ChatConfig.load())

  notice "program started"

  var
    tui = ChatTUI.new(dataDir)
    tuiPtr {.threadvar.}: pointer

  tuiPtr = cast[pointer](tui)
  proc stop() {.noconv.} = waitFor cast[ChatTUI](tuiPtr).stop()
  setControlCHook(stop)

  await tui.start()
  while tui.running: poll()

  notice "program exited"

when isMainModule: waitFor main()
