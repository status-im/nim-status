## chat is an example program demonstrating usage of nim-status

when not(compileOption("threads")):
  {.fatal: "Please compile this program with the --threads:on option!".}

import # vendor libs
  chronos

import # chat libs
  ./chat/[chat_impl, tui]

proc main() {.async.} =
  ChatTUI.new(ChatClient.new(ChatClientConfig.load())).start()

when isMainModule:
  waitFor(main())
