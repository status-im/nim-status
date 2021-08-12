import # std libs
  std/[options, os, unittest]

import # vendor libs
  chronos, json_serialization, sqlcipher

import # status lib
  status/private/[common, database, permissions]

import # test modules
  ./test_helpers

procSuite "permissions":
  asyncTest "permissions":
    let password = "qwerty"
    let path = currentSourcePath.parentDir() & "/build/my.db"
    removeFile(path)
    let dbResult = initDb(path, password)
    check dbResult.isOk
    let db = dbResult.get

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

    check:
      db.addPermissions(dappPerm1).isOk
      db.addPermissions(dappPerm2).isOk
      db.addPermissions(dappPerm3).isOk

    var dappPerms = db.getPermissions()

    check:
      dappPerms.isOk
      dappPerms.get == @[dappPerm1, dappPerm2, dappPerm3]
      # ensure serialized result is the same as status-go's RPC response
      Json.encode(dappPerms.get) == """[{"dapp":"Dapp1","permissions":["perm1a"]},{"dapp":"Dapp2","permissions":["perm2a","perm2b"]},{"dapp":"Dapp3","permissions":[]}]"""

    check db.deletePermission(dappPerm2.name).isOk
    dappPerms = db.getPermissions()

    check:
      dappPerms.isOk
      dappPerms.get == @[dappPerm1, dappPerm3]

    db.close()
    removeFile(path)
