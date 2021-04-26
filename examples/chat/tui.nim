import # chat libs
  ./chat_impl

# TUI: https://en.wikipedia.org/wiki/Text-based_user_interface

type ChatTUI* = ref object
  client*: ChatClient
  running*: bool

# ChatTUI's job will be to dispatch on event type to appropriate proc/s, which
# will mainly involve printing messages in events from the client and taking
# action/s based on user events, e.g. calling a client proc to send a message
# or displaying a list of possible commands when user enters `/help` or `/?`

# `new` should instantiate a TaskRunner
proc new*(T: type ChatTUI, client: ChatClient): T =
  T(client: client, running: true)

proc start*(tui: ChatTUI) =
  # before starting the client or tui's task runner, should prep tui to accept
  # events coming from the client and user
  # before starting the client, start tui's task runner, which in turn starts a
  # thread dedicated to monitoring user input/actions
  tui.client.start()
  echo "tui.client.config: " & $tui.client.config
  echo "tui.client.dataDir: " & $tui.client.dataDir

proc stop*(tui: ChatTUI) =
  echo "\n"
  tui.client.stop()
  echo "stopping the TUI..."
  tui.running = false
