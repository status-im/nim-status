{.push raises: [Defect].}
import # std libs
  std/strutils

import # vendor libs
  stew/results

import # status modules
  ./types

const
  HARDENED_INDEX: uint32 = 1 shl 31
  PATH_WALLET_ROOT* = KeyPath("m/44'/60'/0'/0")
  PATH_EIP_1581* = KeyPath("m/43'/60'/1581'")
    # EIP1581 Root Key, the extended key from which any whisper key/encryption
    # key can be derived
  PATH_DEFAULT_WALLET* = KeyPath(PATH_WALLET_ROOT.string & "/0")
    # BIP44-0 Wallet key, the default wallet key
  PATH_WHISPER* = KeyPath(PATH_EIP_1581.string & "/0'/0")
    # EIP1581 Chat Key 0, the default whisper key

proc isNonHardened*(self: PathLevel): bool {.raises: [].} =
  (self.uint32 and HARDENED_INDEX) == 0

func parse(T: type PathLevel, value: string): PathLevelResult {.raises:
  [].} =

  var child: string
  var mask: uint32

  try:
    if value.endsWith("'"):
      child = value[0..^2]
      mask = HARDENED_INDEX
    else:
      child = value
      mask = 0

    let index: uint32 = parseUInt(child).uint32
    if (index and HARDENED_INDEX) == 0:
      return PathLevelResult.ok(PathLevel (index or mask))
    else:
      return PathLevelResult.err("Invalid index number")
  except ValueError as e:
    return PathLevelResult.err "Error parsing path level: " & e.msg

proc toBEBytes*(x: PathLevel): array[4, byte] {.raises: [].} =
  # BigEndian
  result[3] = ((x.uint32 shr  0) and 0xff).byte
  result[2] = ((x.uint32 shr  8) and 0xff).byte
  result[1] = ((x.uint32 shr 16) and 0xff).byte
  result[0] = ((x.uint32 shr 24) and 0xff).byte

iterator pathNodes*(path: KeyPath): PathLevelResult {.raises: [].} =
  try:
    for elem in path.string.split("/"):
      if elem == "m": continue
      yield PathLevel.parse(elem)
  except ValueError:
    doAssert false, "Invalid Key Path"
