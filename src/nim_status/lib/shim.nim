import strformat
import ../lib

proc hashMessage*(message: string): string =
  let hash = lib.hashMessage(message)
  fmt("{{\"result\":\"{hash}\"}}")

export generateAlias

export saveAccountAndLogin

# ==============================================================================
# TEST - Send / Receive Messages - START
export test_subscribe
export test_sendMessage
# TEST - Send / Receive Messages - END
# ==============================================================================
