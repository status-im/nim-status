{.push raises: [Defect].}

import # std libs
  std/[json, options, strformat]

import # vendor libs
  chronos, json_serialization,
  json_serialization/[lexer, reader, writer],
  sqlcipher

import # status modules
  ../common, ../conversions, ../settings, ../database

type
  PublicAccount* {.dbTableName("accounts").} = object
    creationTimestamp* {.serializedFieldName("creationTimestamp"), dbColumnName("creationTimestamp").}: int64
    name* {.serializedFieldName("name"), dbColumnName("name").}: string
    identicon* {.serializedFieldName("identicon"), dbColumnName("identicon").}: string
    keycardPairing* {.serializedFieldName("keycardPairing"), dbColumnName("keycardPairing").}: string
    keyUid* {.serializedFieldName("keyUid"), dbColumnName("keyUid").}: string
    loginTimestamp* {.serializedFieldName("loginTimestamp"), dbColumnName("loginTimestamp").}: Option[int64]

proc deleteAccount*(db: DbConn, keyUid: string): DbResult[void] {.raises: [].} =

  try:

    var tblAccounts: PublicAccount
    let query = fmt"""DELETE FROM {tblAccounts.tableName}
                      WHERE       {tblAccounts.keyUid.columnName} = ?"""

    db.exec(query, keyUid)
    ok()

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc getPublicAccount*(db: DbConn, keyUid: string):
  DbResult[Option[PublicAccount]] =

  try:

    var tblAccounts: PublicAccount
    let query = fmt"""SELECT    {tblAccounts.creationTimestamp.columnName},
                                {tblAccounts.name.columnName},
                                {tblAccounts.loginTimestamp.columnName},
                                {tblAccounts.identicon.columnName},
                                {tblAccounts.keycardPairing.columnName},
                                {tblAccounts.keyUid.columnName}
                      FROM      {tblAccounts.tableName}
                      WHERE     {tblAccounts.keyUid.columnName}= ?"""
    ok db.one(PublicAccount, query, keyUid)

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc getPublicAccounts*(db: DbConn): DbResult[seq[PublicAccount]] =

  try:

    var tblAccounts: PublicAccount
    let query = fmt"""SELECT    {tblAccounts.creationTimestamp.columnName},
                                {tblAccounts.name.columnName},
                                {tblAccounts.loginTimestamp.columnName},
                                {tblAccounts.identicon.columnName},
                                {tblAccounts.keycardPairing.columnName},
                                {tblAccounts.keyUid.columnName}
                      FROM      {tblAccounts.tableName}
                      ORDER BY  {tblAccounts.creationTimestamp.columnName} ASC"""
    ok db.all(PublicAccount, query)

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc saveAccount*(db: DbConn, account: PublicAccount): DbResult[void] {.raises:
  [].} =

  try:

    var tblAccounts: PublicAccount
    let query = fmt"""
      INSERT OR REPLACE INTO  {tblAccounts.tableName} (
                              {tblAccounts.creationTimestamp.columnName},
                              {tblAccounts.name.columnName},
                              {tblAccounts.identicon.columnName},
                              {tblAccounts.keycardPairing.columnName},
                              {tblAccounts.keyUid.columnName},
                              {tblAccounts.loginTimestamp.columnName})
      VALUES                  (?, ?, ?, ?, ?, NULL)"""

    db.exec(query, account.creationTimestamp, account.name, account.identicon,
      account.keycardPairing, account.keyUid)
    ok()

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc updateAccount*(db: DbConn, account: PublicAccount): DbResult[void] =

  try:

    var tblAccounts: PublicAccount
    let query = fmt"""UPDATE  {tblAccounts.tableName}
                      SET     {tblAccounts.creationTimestamp.columnName} = ?,
                              {tblAccounts.name.columnName} = ?,
                              {tblAccounts.identicon.columnName} = ?,
                              {tblAccounts.keycardPairing.columnName} = ?,
                              {tblAccounts.loginTimestamp.columnName} = ?
                      WHERE   {tblAccounts.keyUid.columnName}= ?"""

    db.exec(query, account.creationTimestamp, account.name, account.identicon,
      account.keycardPairing, account.loginTimestamp, account.keyUid)
    ok()

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc updateAccountTimestamp*(db: DbConn, loginTimestamp: int64, keyUid: string):
  DbResult[void] {.raises: [].} =

  try:

    var tblAccounts: PublicAccount
    let query = fmt"""UPDATE  {tblAccounts.tableName}
                      SET     {tblAccounts.loginTimestamp.columnName} = ?
                      WHERE   {tblAccounts.keyUid.columnName} = ?"""

    db.exec(query, loginTimestamp, keyUid)
    ok()

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError
