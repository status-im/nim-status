
import json, options
import web3/ethtypes
import sqlcipher

proc parseAddress*(strAddress: string): Address =
  fromHex(Address, strAddress)

proc getOption*[T](self: JsonNode, key: string): Option[T] =
  if not self.hasKey(key):
    result = none(T)
  else:
    # handle special cases
    when T is Address:
      result = if self{key}.getStr == "": none(T) else: some(parseAddress(self[key].getStr))
    when T is JsonNode:
      result = if self[key].kind == JNull: none(T) else: some(self[key])
    when T is int64:
      result = if self[key].getBiggestInt == 0: none(T) else: some(self[key].getBiggestInt)
    # for all other (default) cases
    when T is string:
      result = if self{key}.getStr == "": none(T) else: some(self[key].getStr)
    when T is bool:
      result = if not self{key}.getBool: none(T) else: some(self[key].getBool)
    else:
      result = some(self[key].to(T))

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
