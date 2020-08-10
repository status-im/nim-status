import ../lib
import lib/shim as nim_shim_c
import sys

proc hashMessage*(message: cstring): cstring =
  let hash = lib.hashMessage($message)
  result = cast[cstring](c_malloc(csize_t hash.len + 1))
  copyMem(result, hash.cstring, hash.len)
  result[hash.len] = '\0'

let generateAlias* = nim_shim_c.generateAlias
