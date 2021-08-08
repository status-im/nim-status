{.push raises: [Defect].}

import # std libs
  std/[sequtils, strformat, sugar, tables]

import # vendor libs
  json_serialization, sqlcipher, stew/byteutils

from stew/shims/macros as stew_macros import hasCustomPragmaFixed,
  getCustomPragmaFixed

import # status modules
  ./common, ./conversions

type
  Dapp* {.dbTableName("dapps").} = object
    name* {.dbColumnName("name").}: string

  DappPermissions* {.dbTableName("permissions").} = object
    name* {.
      serializedFieldName("dapp"),
      dbColumnName("dapp_name"),
      dbForeignKey(Dapp)
    .}: string
    permissions* {.
      serializedFieldName("permissions"),
      dbColumnName("permission")
    .}: seq[string]

  DappPermissionsDbError* = object of StatusError


proc addPermissions*(db: DbConn, dappPerms: DappPermissions) {.raises: [Defect,
  DappPermissionsDbError].} =

  const errorMsg = "Error adding dapp permissions in to the database"

  try:
    var dapp: Dapp
    var dappPermission: DappPermissions
    var query = fmt"""INSERT OR REPLACE INTO  {dapp.tableName}
                                              (
                                                {dapp.name.columnName}
                                              )
                      VALUES                  (?)"""

    db.exec(query, dappPerms.name)

    if dappPerms.permissions.len == 0:
      return

    query = fmt"""INSERT INTO {dappPermission.tableName}
                    (
                      {dappPermission.name.columnName},
                      {dappPermission.permissions.columnName}
                    )
                  VALUES(?, ?)"""
    for perm in dappPerms.permissions:
      db.exec(query, dappPerms.name, @[perm])
  except SqliteError as e:
    raise (ref DappPermissionsDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref DappPermissionsDbError)(parent: e, msg: errorMsg)

proc getPermissions*(db: DbConn): seq[DappPermissions] {.raises: [Defect,
  DappPermissionsDbError].} =

  const errorMsg = "Error getting dapp permissions from the database"
  try:

    var
      dapp: Dapp
      dappPermission: DappPermissions
    var query = fmt"""SELECT {dapp.name.columnName}
                      FROM {dapp.tableName}"""

    let dapps = db.all(Dapp, query)
    if dapps.len == 0:
      return result

    var tblDappPerms = dapps.map(dapp => (dapp.name, DappPermissions(name: dapp.name))).toOrderedTable()

    query = fmt"""SELECT
                        {dappPermission.name.columnName},
                        {dappPermission.permissions.columnName}
                      FROM {dappPermission.tableName}"""

    let dappPerms = db.all(DappPermissions, query)
    for dappPerm in dappPerms:
      if not tblDappPerms.hasKey(dappPerm.name):
        continue
      var existing = tblDappPerms[dappPerm.name]
      existing.permissions = existing.permissions & dappPerm.permissions
      tblDappPerms[dappPerm.name] = existing
    return toSeq(tblDappPerms.values)

  except SerializationError as e:
    raise (ref DappPermissionsDbError)(parent: e, msg: errorMsg)
  except SqliteError as e:
    raise (ref DappPermissionsDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref DappPermissionsDbError)(parent: e, msg: errorMsg)


proc deletePermission*(db: DbConn, name: string) {.raises:
  [DappPermissionsDbError].} =

  const errorMsg = "Error deleting dapp permission from the database"
  try:
    var dapp: Dapp
    let query = fmt"""DELETE FROM   {dapp.tableName}
                      WHERE         {dapp.name.columnName} = ?"""

    db.exec(query, name)
    # Note: No need to also delete permissions from the permissions table due to
    # `FOREIGN KEY(dapp_name) REFERENCES dapps(name) ON DELETE CASCADE`
  except SqliteError as e:
    raise (ref DappPermissionsDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref DappPermissionsDbError)(parent: e, msg: errorMsg)
