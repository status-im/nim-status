
import json, options
import web3/ethtypes
import sqlcipher

proc parseAddress*(strAddress: string): Address =
  fromHex(Address, strAddress)

proc toOption*[T](self: DbValue): Option[T] =
  if self.kind == sqliteNull:
    result = none(T)
  else:
    when T is bool:
      result = if self.intVal == 0: none(T) else: some(true)
    when T is int64 or T is int:
      result = if self.intVal == 0: none(T) else: some(self.intVal)
    when T is JsonNode:
      result = if self.strVal == "": none(T) else: some(self.strVal.parseJson)
    when T is Address:
      result = if self.strVal == "": none(T) else: some(self.strVal.parseAddress)
    when T is string:
      result = if self.strVal == "": none(T) else: some(self.strVal)

