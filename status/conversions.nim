{.push raises: [Defect].}

import # std libs
  std/[json, options, strutils, times, typetraits]

import # vendor libs
  chronicles, eth/keys, json_serialization,
  json_serialization/std/options as json_options, secp256k1, stew/byteutils,
  sqlcipher, web3/[conversions, ethtypes]

import # status libs
  ./extkeys/types as key_types

from ./tx_history/types as tx_history_types import TxType

# needed because nim-sqlcipher calls toDbValue/fromDbValue which does not have
# json_serialization/std/options imported
export conversions, ethtypes, json_options

const dtFormat = "yyyy-MM-dd HH:mm:ss fffffffff"

proc fromDbValue*(val: DbValue, T: typedesc[Address]): Address {.raises:
  [Defect, ValueError].} =

  val.strVal.parseAddress

proc fromDbValue*(val: DbValue, T: typedesc[DateTime]): DateTime {.raises:
  [Defect, TimeParseError].} =

  val.strVal.parse(dtFormat)

proc fromDbValue*(val: DbValue, T: typedesc[JsonNode]): JsonNode {.raises:
  [Defect, Exception].} =

  val.strVal.parseJson

proc fromDbValue*(val: DbValue, T: typedesc[KeyPath]): KeyPath {.raises: [].} =
  KeyPath val.strVal

proc fromDbValue*(val: DbValue, T: typedesc[SkPublicKey]): SkPublicKey =
  let pubKeyResult = SkPublicKey.fromRaw(val.blobVal)
  if pubKeyResult.isErr:
    # TODO: implement chronicles in nim-status (in the tests)
    echo "error converting db value to public key, error: " &
      $(pubKeyResult.error)
    return
  pubKeyResult.get

proc fromDbValue*(val: DbValue, T: typedesc[TxType]): TxType {.raises: [Defect,
  ref ValueError].} =

  parseEnum[TxType](val.strVal)

proc fromDbValue*[T: seq[auto]](val: DbValue, _: typedesc[T]): T {.raises:
  [Defect, SerializationError].} =

  Json.decode(val.strVal, T, allowUnknownFields = true)

# Strips leading zeroes and appends 0x prefix
proc intToHex*(n: int): string {.raises: [].} =
  if n == 0:
    return "0x0"
  var s = n.toHex
  s.removePrefix({'0'})
  result = "0x" & s

proc parseAddress*(address: string): Address {.raises: [Defect, ValueError].} =
  Address.fromHex(address)

proc readValue*(r: var JsonReader, T: type KeyPath): T =
  KeyPath r.readValue(string)

proc toAddress*(secretKey: SkSecretKey): Address {.raises: [Defect,
  ValueError].} =

  let
    publicKey = secretKey.toPublicKey
    address = (PublicKey publicKey).toAddress
  address.parseAddress

proc toDbValue*[T: Address](val: T): DbValue =
  DbValue(kind: sqliteText, strVal: $val)

proc toDbValue*(val: DateTime): DbValue {.raises: [].} =
  DbValue(kind: sqliteText, strVal: val.format(dtFormat))

proc toDbValue*(val: JsonNode): DbValue {.raises: [].} =
  DbValue(kind: sqliteText, strVal: $val)

proc toDbValue*(val: KeyPath): DbValue {.raises: [].} =
  DbValue(kind: sqliteText, strVal: val.string)

proc toDbValue*[T: seq[auto]](val: T): DbValue =
  DbValue(kind: sqliteText, strVal: Json.encode(val))

proc toDbValue*(val: SkPublicKey): DbValue {.raises: [Defect, ValueError].} =
  DbValue(kind: sqliteBlob, blobVal: ($val).hexToSeqByte)

proc toDbValue*(val: TxType): DbValue {.raises: [].} =
  DbValue(kind: sqliteText, strVal: $val)

proc writeValue*(w: var JsonWriter, v: KeyPath) =
  w.writeValue distinctBase(v)
