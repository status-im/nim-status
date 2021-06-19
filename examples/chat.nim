## chat.nim is an example program demonstrating usage of nim-status, nim-waku,
## nim-task-runner, and nim-ncurses

when not(compileOption("threads")):
  {.fatal: "Please compile this program with the --threads:on option!".}

# exporting the following modules from ./chat/config doesn't work as expected,
# so import them here as a workaround
import # vendor libs
  eth/keys, libp2p/crypto/crypto
import
  confutils/std/net except completeCmdArg, parseCmdArg

import # chat libs
  ./chat/tui

logScope:
  topics = "chat"

proc main() {.async.} =
  let chatConfig = handleConfig(ChatConfig.load())

  notice "program started"

  var
    tui = ChatTUI.new(chatConfig)
    tuiPtr {.threadvar.}: pointer

  tuiPtr = cast[pointer](tui)
  proc stop() {.noconv.} = waitFor cast[ChatTUI](tuiPtr).stop()
  setControlCHook(stop)

  await tui.start()
  while tui.running: poll()

  notice "program exited"

when isMainModule: waitFor main()
