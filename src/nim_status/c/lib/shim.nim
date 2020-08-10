import ../../lib/shim as nim_shim
import ../sys

proc hashMessage*(message: cstring): cstring =
  let hash = nim_shim.hashMessage($message)
  result = cast[cstring](c_malloc(csize_t hash.len + 1))
  copyMem(result, hash.cstring, hash.len)
  result[hash.len] = '\0'

proc generateAlias*(pubKey: cstring): cstring =
  let alias = nim_shim.generateAlias($pubKey)
  result = cast[cstring](c_malloc(csize_t alias.len + 1))
  copyMem(result, alias.cstring, alias.len)
  result[alias.len] = '\0'
