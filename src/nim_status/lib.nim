import lib/util
import nimcrypto
import strutils
import unicode

const END_OF_MEDIUM = Rune(0x19).toUTF8
const prefix = END_OF_MEDIUM & "Ethereum Signed Message:\n"

proc hashMessage*(message: string): string =
  ## hashMessage calculates the hash of a message to be safely signed by the keycard
  ## The hash is calulcated as
  ##  keccak256("\x19Ethereum Signed Message:\n"${message length}${message}).
  ## This gives context to the signed message and prevents signing of transactions.
  var msg = message
  if isHexString(msg):
    try:
      msg = parseHexStr(msg[2..^1])
    except:
      discard
  "0x" & toLower($keccak_256.digest(prefix & $(msg.len) & msg))
