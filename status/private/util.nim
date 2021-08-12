{.push raises: [Defect].}

import # std libs
  std/[re, strutils, tables, unicode]

import # vendor libs
  nimcrypto, stew/results, web3/ethtypes

export re

type
  UtilError* = enum
    ParseHexError       = "utils: error parsing string to hex"
    RegexIsHexError     = "utils: regex error checking for hex in string"
    RegexIsPubKeyError  = "utils: regex error checking for public key in string"

  UtilResult*[T] = Result[T, UtilError]

const hexPattern = "^[0-9a-f]+$"

template catchEx*(body: typed): Result[type(body), ref Exception] =
  # Variant of `nim-result`s `catch` template, where Exceptions are
  # caught as well. nim-result only catches CatchableError, which
  # should be sufficient in nim v1.4+.
  type R = Result[type(body), ref Exception]

  try:
    R.ok(body)
  except Defect as d:
    raise d
  except Exception as e:
    R.err(e)

proc isHexString*(str: string): UtilResult[bool] {.raises: [].} =
  try:
    let reHex = re(hexPattern, {reIgnoreCase})
    ok  str.len > 3 and
        str.len mod 2 == 0 and
        str[0..1] == "0x" and
        match(str[2..^1], reHex)
  except RegexError:
    err RegexIsHexError

proc isPubKey*(str: string): UtilResult[bool] {.raises: [].} =
  try:
    let reHex = re(hexPattern, {reIgnoreCase})
    ok  str.len == 132 and
        str[0..3] == "0x04" and
        match(str[2..^1], reHex)
  except RegexError:
    err RegexIsPubKeyError

proc hashMessage*(message: string): UtilResult[string] {.raises: [].} =

  ## hashMessage calculates the hash of a message to be safely signed by the keycard.
  ## The hash is calulcated as
  ##  keccak256("\x19Ethereum Signed Message:\n"${message length}${message}).
  ## This gives context to the signed message and prevents signing of transactions.
  var msg = message
  if ?isHexString(msg):
    try:
      msg = parseHexStr(msg[2..^1])
    except:
      return err ParseHexError
  const END_OF_MEDIUM = Rune(0x19).toUTF8
  const prefix = END_OF_MEDIUM & "Ethereum Signed Message:\n"
  ok "0x" & toLower($keccak_256.digest(prefix & $(msg.len) & msg))

proc indexOf*[T](s: seq[T], item: T): int =
  var i = 0
  for i in 0..s.len:
    if s[i] == item:
      return i
  return -1

proc mapErrTo*[T, E1, E2](r: Result[T, E1], v: E2):
  Result[T, E2] {.raises: [].} =

  r.mapErr(proc (e: E1): E2 = v)

proc mapErrTo*[T, E1, E2](r: Result[T, E1], t: Table[E1, E2], default: E2):
  Result[T, E2] {.raises: [].} =

  r.mapErr(proc (e: E1): E2 =
    if not t.hasKey e:
      return default
    try:
      return t[e]
    except KeyError:
      return default)
