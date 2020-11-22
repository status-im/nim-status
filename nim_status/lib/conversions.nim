import
  json, options

import
  web3/ethtypes, sqlcipher

proc parseAddress*(strAddress: string): Address =
  fromHex(Address, strAddress)

proc fromDbValue*(val: DbValue, T: typedesc[JsonNode]): JsonNode = val.strVal.parseJson

proc fromDbValue*(val: DbValue, T: typedesc[Address]): Address = val.strVal.parseAddress