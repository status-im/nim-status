import strformat
import ../lib

proc hashMessage*(message: string): string =
  let hash = lib.hashMessage(message)
  fmt("{{\"result\":\"{hash}\"}}")
