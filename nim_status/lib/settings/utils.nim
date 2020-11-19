
import json, options
import web3/ethtypes
import sqlcipher

proc parseAddress*(strAddress: string): Address =
  fromHex(Address, strAddress)

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