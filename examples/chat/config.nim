import # std libs
  os

import # vendor libs
  confutils

export confutils

proc defaultDataDir*(): string =
  # logic here could evolve to something more complex (e.g. platform-specific)
  # like the `defaultDataDir()` of status-desktop
  joinPath(getCurrentDir(), "data")

type ChatClientConfig* = object
  dataDir* {.
    abbr: "d"
    defaultValue: defaultDataDir()
    desc: "Chat client data directory"
  .}: string
