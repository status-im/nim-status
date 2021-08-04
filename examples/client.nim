## client.nim is an example program demonstrating usage of nim-status,
## nim-waku, nim-task-runner, and nim-ncurses

when not(compileOption("threads")):
  {.fatal: "Please compile this program with the --threads:on option!".}

import # client modules
  ./client/tui

logScope:
  topics = "main"

proc main() {.async.} =
  let config = handleConfig(ClientConfig.load())

  notice "program started"

  var tui = Tui.new(config)
  await tui.start()
  while tui.running: poll()

  notice "program exited"

when isMainModule:
  # client program will handle all control characters with ncurses in raw mode
  proc nop() {.noconv.} = discard
  setControlCHook(nop)

  waitFor main()

  # avoid exception at program exit related to a problem with a thread started
  # by nim-eth/nim-nat-traversal sometimes not having shut down cleanly by the
  # time client program is ready to exit
  quit(QuitSuccess)
