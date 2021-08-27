{.push raises: [Defect].}

import # std libs
  std/[json, marshal, options, strutils, times, typetraits]

import # vendor libs
  chronicles, eth/keys, json_serialization,
  json_serialization/std/options as json_options,
  json_serialization/[reader, writer, lexer], secp256k1, stew/byteutils,
  sqlcipher, web3/[conversions, ethtypes]

import # status modules
  ./common, ./chatmessages/common as chatmessages, ./extkeys/types as key_types

from ./tx_history/types as tx_history_types import TxType

# needed because nim-sqlcipher calls toDbValue/fromDbValue which does not have
# json_serialization/std/options imported
export conversions, ethtypes, json_options, secp256k1, reader, writer, lexer

type
  ConversionError* = object of StatusError
  ConversionError2* = enum
    InvalidAddress = "cnv: unable to parse address, invalid address string"

  ConversionResult*[T] = Result[T, ConversionError2]

const dtFormat = "yyyy-MM-dd HH:mm:ss fffffffff"

proc fromDbValue*(val: DbValue, T: typedesc[Address]): Address {.raises:
  [Defect, ValueError].} =

  Address.fromHex(val.strVal)

proc fromDbValue*(val: DbValue, T: typedesc[DateTime]): DateTime {.raises:
  [Defect, TimeParseError].} =

  val.strVal.parse(dtFormat)

proc fromDbValue*(val: DbValue, T: typedesc[JsonNode]): JsonNode {.raises:
  [Defect, Exception].} =

  val.strVal.parseJson

proc fromDbValue*(val: DbValue, T: typedesc[KeyPath]): KeyPath {.raises: [].} =
  KeyPath val.strVal

proc fromDbValue*(val: DbValue, T: typedesc[Message]): Message {.raises:
  [ConversionError].} =

  const errorMsg = "Error converting DB value in to a Message type"
  try:
    Json.decode(string.fromBytes(val.blobVal), Message,
      allowUnknownFields = true)
  except ValueError as e:
    raise (ref ConversionError)(parent: e, msg: errorMsg)
  except Exception as e:
    raise (ref ConversionError)(parent: e, msg: errorMsg)

proc fromDbValue*(val: DbValue, T: typedesc[NetworkId]): NetworkId =
  NetworkId val.intVal

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

proc parseAddress*(address: string): ConversionResult[Address] =
  try:
    ok Address.fromHex(address)
  except ValueError:
    err InvalidAddress

proc readValue*(r: var JsonReader, T: type KeyPath): T =
  KeyPath r.readValue(string)

proc readValue*(r: var JsonReader, U: type Message): U {.raises: [Defect,
  ConversionError].} =

  const errorMsg = "Error deserialising string in to a Message type"

  try:
    # FIXME: this will NOT adhere to the {.serializedFieldName.} metadata
    # on the Message fields as it uses the std/marshal module to deserialise the
    # object. At this point, it is unknown how to workaround this
    # limitation without causing an infinite loop. IOW, it would be great to be
    # able to call `r.readValue(Message)`, but that would cause this proc to be
    # called in an infinite loop. HELP WANTED, PLEASE! 🙏
    # To illustrate the issue, change the value of MessageType.StickerPack to
    # "stickerPack123". Upon attempting to deserialise using Nim's marshal
    # module, the field "stickerPack123" will not be found on the Message type.
    let jsn = r.readValue(JsonNode)
    return ($jsn).to[:Message]
  except IOError as e:
    raise (ref ConversionError)(parent: e, msg: errorMsg)
  except JsonParsingError as e:
    raise (ref ConversionError)(parent: e, msg: errorMsg)
  except OSError as e:
    raise (ref ConversionError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref ConversionError)(parent: e, msg: errorMsg)
  except Exception as e:
    raise (ref ConversionError)(parent: e, msg: errorMsg)

proc toAddress*(secretKey: SkSecretKey): ConversionResult[Address] =

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

proc toDbValue*(val: Message): DbValue =
  DbValue(kind: sqliteBlob, blobVal: Json.encode(val).toBytes)

proc toDbValue*(val: NetworkId): DbValue =
  DbValue(kind: sqliteInteger, intVal: val.int)

proc toDbValue*[T: seq[auto]](val: T): DbValue =
  DbValue(kind: sqliteText, strVal: Json.encode(val))

proc toDbValue*(val: SkPublicKey): DbValue {.raises: [Defect, ValueError].} =
  DbValue(kind: sqliteBlob, blobVal: ($val).hexToSeqByte)

proc toDbValue*(val: TxType): DbValue {.raises: [].} =
  DbValue(kind: sqliteText, strVal: $val)

proc writeValue*(w: var JsonWriter, v: KeyPath) =
  w.writeValue distinctBase(v)
