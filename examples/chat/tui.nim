import # chat libs
  ./chat_impl

# TUI: https://en.wikipedia.org/wiki/Text-based_user_interface

type ChatTUI* = ref object
  client*: ChatClient

proc new*(T: type ChatTUI, client: ChatClient): T =
  T(client: client)

proc start*(tui: ChatTUI) =
  echo tui.client.config
  echo tui.client.dataDir
  tui.client.start()
