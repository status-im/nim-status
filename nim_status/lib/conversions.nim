import
  json, options

import
  web3/ethtypes, sqlcipher, json_serialization, stew/byteutils

proc parseAddress*(strAddress: string): Address =
  fromHex(Address, strAddress)

proc toDbValue*[T: Address](val: T): DbValue =
  DbValue(kind: sqliteText, strVal: $val)

proc toDbValue*(val: JsonNode): DbValue =
  DbValue(kind: sqliteText, strVal: $val)

proc fromDbValue*(val: DbValue, T: typedesc[JsonNode]): JsonNode = val.strVal.parseJson

proc fromDbValue*(val: DbValue, T: typedesc[Address]): Address = val.strVal.parseAddress