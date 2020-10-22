
import json, options
import web3/ethtypes
import sqlcipher

proc parseAddress*(strAddress: string): Address =
  fromHex(Address, strAddress)

proc getOptionInt*(self: JsonNode, key: string): Option[int] =
  if not self.hasKey(key) or self{key}.getInt() == 0:
    result = none(int)
  else:
    result = some(self[key].getInt)

proc getOptionInt64*(self: JsonNode, key: string): Option[int64] =
  if not self.hasKey(key) or self{key}.getBiggestInt == 0.int64:
    result = none(int64)
  else:
    result = some(self[key].getBiggestInt)

proc getOptionBool*(self: JsonNode, key: string): Option[bool] =
  if not self.hasKey(key) or not self{key}.getBool:
    result = none(bool)
  else:
    result = some(self[key].getBool)

proc getOptionString*(self: JsonNode, key: string): Option[string] =
  if not self.hasKey(key) or self{key}.getStr == "":
    result = none(string)
  else:
    result = some(self[key].getStr)

proc getOptionAddress*(self: JsonNode, key: string): Option[Address] =
  if not self.hasKey(key) or self{key}.getStr == "":
    result = none(Address)
  else:
    result = some(parseAddress(self[key].getStr))

proc getOptionJsonNode*(self: JsonNode, key: string): Option[JsonNode] =
  if not self.hasKey(key) or self[key].kind == JNull:
    result = none(JsonNode)
  else:
    result = some(self[key])

proc addOptionalValue*[T](self: var JsonNode, key: string, value: Option[T]) =
  if value.isSome:
    self[key] = %* value.get()

proc optionBool*(self: DbValue): Option[bool] =
  if self.kind == sqliteNull or self.intVal == 0:
    return none(bool)
  return some(true)

proc optionInt64*(self: DbValue): Option[int64] =
  if self.kind == sqliteNull or self.intVal == 0:
    return none(int64)
  return some(self.intVal)

proc optionInt*(self: DbValue): Option[int64] =
  if self.kind == sqliteNull or self.intVal == 0:
    return none(int64)
  return some(self.intVal)

proc optionString*(self: DbValue): Option[string] =
  if self.kind == sqliteNull or self.strVal == "":
    return none(string)
  return some(self.strVal)

proc optionAddress*(self: DbValue): Option[Address] =
  if self.kind == sqliteNull or self.strVal == "":
    return none(Address)
  return some(self.strVal.parseAddress)

proc optionJsonNode*(self: DbValue): Option[JsonNode] =
  if self.kind == sqliteNull or self.strVal == "":
    return none(JsonNode)
  return some(self.strVal.parseJson)
