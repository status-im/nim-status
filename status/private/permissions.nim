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


proc addPermissions*(db: DbConn, dappPerms: DappPermissions): DbResult[void] =

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
      return ok()

    query = fmt"""INSERT INTO {dappPermission.tableName}
                    (
                      {dappPermission.name.columnName},
                      {dappPermission.permissions.columnName}
                    )
                  VALUES(?, ?)"""
    for perm in dappPerms.permissions:
      db.exec(query, dappPerms.name, @[perm])
    ok()
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc getPermissions*(db: DbConn): DbResult[seq[DappPermissions]] =

  try:

    var
      dapp: Dapp
      dappPermission: DappPermissions
    var query = fmt"""SELECT {dapp.name.columnName}
                      FROM {dapp.tableName}"""

    let dapps = db.all(Dapp, query)
    if dapps.len == 0:
      return result

    var tblDappPerms =
      dapps.map(dapp => (dapp.name, DappPermissions(name: dapp.name)))
      .toOrderedTable()

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
    ok(toSeq(tblDappPerms.values))

  except SerializationError: err DataAndTypeMismatch
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError


proc deletePermission*(db: DbConn, name: string): DbResult[void] {.raises:
  [].} =

  try:
    var dapp: Dapp
    let query = fmt"""DELETE FROM   {dapp.tableName}
                      WHERE         {dapp.name.columnName} = ?"""

    db.exec(query, name)
    # Note: No need to also delete permissions from the permissions table due to
    # `FOREIGN KEY(dapp_name) REFERENCES dapps(name) ON DELETE CASCADE`
    ok()
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError
