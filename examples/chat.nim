## chat is an example program demonstrating usage of nim-status

when not(compileOption("threads")):
  {.fatal: "Please compile this program with the --threads:on option!".}

import # vendor libs
  chronos

import # chat libs
  ./chat/[chat_impl, tui]

proc main() {.async.} =
  var tui = ChatTUI.new(ChatClient.new(ChatClientConfig.load()))
  var tuiPtr {.threadvar.}: pointer
  tuiPtr = cast[pointer](tui)

  proc stop() {.noconv.} = cast[ChatTUI](tuiPtr).stop()

  setControlCHook(stop)

  tui.start()
  while tui.running: poll()

when isMainModule: waitFor(main())
