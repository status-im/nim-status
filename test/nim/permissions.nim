import # nim libs
  os, options

import # vendor libs
  json_serialization

import # nim-status libs
  ../../nim_status/lib/[database, permissions],
  ../../nim_status/lib/migrations/sql_scripts_app

let passwd = "qwerty"
let path = currentSourcePath.parentDir() & "/build/myDatabase"
let db = initializeDB(path, passwd, newMigrationDefinition())

let dappPerm1: DappPermissions = DappPermissions(
  name: "Dapp1",
  permissions: @["perm1a"]
)
let dappPerm2: DappPermissions = DappPermissions(
  name: "Dapp2",
  permissions: @["perm2a", "perm2b"]
)
let dappPerm3: DappPermissions = DappPermissions(
  name: "Dapp3",
  permissions: @[]
)

db.addPermissions(dappPerm1)
db.addPermissions(dappPerm2)
db.addPermissions(dappPerm3)

var dappPerms = db.getPermissions()
assert dappPerms == @[dappPerm1, dappPerm2, dappPerm3]

# ensure serialized result is the same as status-go's RPC response
assert Json.encode(dappPerms) == """[{"dapp":"Dapp1","permissions":["perm1a"]},{"dapp":"Dapp2","permissions":["perm2a","perm2b"]},{"dapp":"Dapp3","permissions":[]}]"""

db.deletePermission(dappPerm2.name)
dappPerms = db.getPermissions()
assert dappPerms == @[dappPerm1, dappPerm3]