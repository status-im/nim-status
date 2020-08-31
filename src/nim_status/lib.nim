import lib/alias
import lib/alias/data
import lib/util
from lib/waku/config as wakuConfig import nil
from lib/waku/node as wakuNode import nil
import nimcrypto
import strformat
import strutils
import unicode
import json

const END_OF_MEDIUM = Rune(0x19).toUTF8
const prefix = END_OF_MEDIUM & "Ethereum Signed Message:\n"

proc hashMessage*(message: string): string =
  ## hashMessage calculates the hash of a message to be safely signed by the keycard.
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

proc generateAlias*(pubKey: string): string =
  ## generateAlias returns a 3-words generated name given a hex encoded (prefixed with 0x) public key.
  ## We ignore any error, empty string is considered an error.
  result = ""
  if isPubKey(pubKey):
    try:
      let seed = truncPubKey(pubKey)
      const poly: uint64 = 0xB8
      let generator = Lsfr(poly: poly, data: seed)
      let adjective1 = adjectives[generator.next mod adjectives.len.uint64]
      let adjective2 = adjectives[generator.next mod adjectives.len.uint64]
      let animal = animals[generator.next mod animals.len.uint64]
      result = fmt("{adjective1} {adjective2} {animal}")
    except:
      discard

proc saveAccountAndLogin*(accountData: string, password: string, settingsJSON: string, configJSON: string, subaccountData: string): string =
  let jConfig = parseJson($configJSON)
  let jSettings = parseJson($settingsJSON)

  let config = wakuConfig.load(jConfig)
  if(config.enabled):
    wakuNode.start(config)

  result = "{}" #TODO: set output 
  #result = status_go.SaveAccountAndLogin(accountData, password, settingsJSON, configJSON, subaccountData)
  

