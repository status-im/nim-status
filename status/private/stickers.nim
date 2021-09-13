{.push raises: [Defect].}

import # std libs
  std/strutils

import # vendor libs
  chronicles, edn, libp2p/[multihash, multicodec, cid], nimcrypto, stint

import
  ./common, ./util

export cid

type
  StickersError* = enum
    CidV0InitFailure      = "stickers: failed to init CIDv0 from codec and multihash"
    EdnNodeTypeUnknown    = "stickers: couldn't decode EDN, node type unknown"
    EdnReadError          = "stickers: error reading EDN string"
    HashValueError        = "stickers: provided hash must not be an empty string"
    HexIntParseError      = "stickers: error parsing string to hex int"
    InvalidMultiCodec     = "stickers: content hash contains an invalid codec"
    MultiHashInitFailure  = "stickers: failed to init MultiHash given the hash"

  StickersResult*[T] = Result[T, StickersError]

  Sticker* = object
    hash*: string
    packId*: int

  StickerPack* = object
    author*: string
    id*: int
    name*: string
    price*: Stuint[256]
    preview*: string
    stickers*: seq[Sticker]
    thumbnail*: string

# forward declaration:
proc parseNode[T](node: EdnNode, searchName: string): StickersResult[T]
proc parseMap[T](map: HMap, searchName: string,): StickersResult[T]

proc getValueFromNode[T](node: EdnNode): StickersResult[T] {.raises: [].} =
  if node.kind == EdnSymbol:
    when T is string:
      return ok node.symbol.name
  elif node.kind == EdnKeyword:
    when T is string:
      return ok node.keyword.name
  elif node.kind == EdnString:
    when T is string:
      return ok node.str
  elif node.kind == EdnCharacter:
    when T is string:
      return ok node.character
  elif node.kind == EdnBool:
    when T is bool:
      return ok node.boolVal
  elif node.kind == EdnInt:
    when T is int:
      return ok node.num.int
  else:
    return err EdnNodeTypeUnknown

proc parseVector[T: seq[Sticker]](node: EdnNode, searchName: string):
  StickersResult[T] =

  var vector: T = @[]

  for i in 0..<node.vec.len:
    var sticker: Sticker
    let child = node.vec[i]
    if child.kind == EdnMap:
      for k, v in sticker.fieldPairs:
        let parseRes = parseMap[v.type](child.map, k)
        v = parseRes.get(default v.type)
      vector.add(sticker)

  return ok vector

proc parseMap[T](map: HMap, searchName: string): StickersResult[T] =
  var res: StickersResult[T]

  for iBucket in 0..<map.buckets.len:
    let bucket = map.buckets[iBucket]
    if bucket.len > 0:
      for iChild in 0..<bucket.len:
        let child = bucket[iChild]
        let isRoot = child.key.kind == EdnSymbol and child.key.symbol.name == "meta"
        if child.key.kind != EdnKeyword and not isRoot:
          continue
        if isRoot or child.key.keyword.name == searchName:
          if child.value.kind == EdnMap:
            res = parseMap[T](child.value.map, searchName)
            break
          elif child.value.kind == EdnVector:
            when T is seq[Sticker]:
              res = parseVector[T](child.value, searchName)
              break
          res = getValueFromNode[T](child.value)
          break

  return res

proc parseNode[T](node: EdnNode, searchName: string): StickersResult[T] =
  if node.kind == EdnMap:
    return parseMap[T](node.map, searchName)
  else:
    return getValueFromNode[T](node)

proc decode*[T](node: EdnNode): StickersResult[T] =
  var res = T()
  for k, v in res.fieldPairs:
    let parseRes = parseNode[v.type](node, k)
    v = parseRes.get(default v.type)
  return ok res

proc decode*[T](edn: string): StickersResult[T] {.raises: [].} =
  try:
    return decode[T](edn.read)
  except IOError, OSError, Exception: # list exception last on purpose
    return err EdnReadError

proc decodeContentHash*(value: string): StickersResult[Cid] =
  if value == "":
    return err HashValueError

  # eg encoded sticker multihash cid:
  #  e30101701220eab9a8ef4eac6c3e5836a3768d8e04935c10c67d9a700436a0e53199e9b64d29
  #  e3017012205c531b83da9dd91529a4cf8ecd01cb62c399139e6f767e397d2f038b820c139f (testnet)
  #  e3011220c04c617170b1f5725070428c01280b4c19ae9083b7e6d71b7a0d2a1b5ae3ce30 (testnet)
  #
  # The first 4 bytes (in hex) represent:
  # e3 = codec identifier "ipfs-ns" for content-hash
  # 01 = unused - sometimes this is NOT included (ie ropsten)
  # 01 = CID version (effectively unused, as we will decode with CIDv0 regardless)
  # 70 = codec identifier "dag-pb"

  # ipfs-ns
  if value[0..1] != "e3":
    return err InvalidMultiCodec

  # dag-pb
  let defaultCodec = ? catch(parseHexInt("70")).mapErrTo(HexIntParseError)
  var
    codec = defaultCodec # no codec specified
    codecStartIdx = 2 # idx of where codec would start if it was specified
  # handle the case when starts with 0xe30170 instead of 0xe3010170
  if value[2..5] == "0101":
    codecStartIdx = 6
    codec = ? catch(parseHexInt(value[6..7])).mapErrTo(HexIntParseError)
  elif value[2..3] == "01" and value[4..5] != "12":
    codecStartIdx = 4
    codec = ? catch(parseHexInt(value[4..5])).mapErrTo(HexIntParseError)

  # strip the info we no longer need
  var multiHashStr = value[codecStartIdx + 2..<value.len]

  # The rest of the hash identifies the multihash algo, length, and digest
  # More info: https://multiformats.io/multihash/
  # 12 = identifies sha2-256 hash
  # 20 = multihash length = 32
  # ...rest = multihash digest
  let
    multiHash = ? MultiHash.init(nimcrypto.fromHex(multiHashStr))
      .mapErrTo(MultiHashInitFailure)
    cid = Cid.init(CIDv0, MultiCodec.codec(codec), multiHash)
      .mapErrTo(CidV0InitFailure)

  trace "Decoded sticker hash", cid = $cid.get
  return cid