{.push raises: [Defect].}

import # std libs
  std/[json, options, strformat, times]

import # vendor libs
  chronos, json_serialization,
  json_serialization/[lexer, reader, writer],
  secp256k1, sqlcipher

import # status modules
  ../conversions, ../common, ../database, ../extkeys/types, ../settings

type
  Account* {.dbTableName("accounts").} = object
    address* {.serializedFieldName("address"), dbColumnName("address").}: Address
    wallet* {.serializedFieldName("wallet"), dbColumnName("wallet").}: Option[bool]
    chat* {.serializedFieldName("chat"), dbColumnName("chat").}: Option[bool]
    `type`* {.serializedFieldName("type"), dbColumnName("type").}: Option[string]
    storage* {.serializedFieldName("storage"), dbColumnName("storage").}: Option[string]
    path* {.serializedFieldName("path"), dbColumnName("path").}: Option[KeyPath]
    publicKey* {.serializedFieldName("pubkey"), dbColumnName("pubkey").}: Option[SkPublicKey]
    name* {.serializedFieldName("name"), dbColumnName("name").}: Option[string]
    color* {.serializedFieldName("color"), dbColumnName("color").}: Option[string]
    createdAt* {.serializedFieldName("created_at"), dbColumnName("created_at").}: DateTime
    updatedAt* {.serializedFieldName("updated_at"), dbColumnName("updated_at").}: DateTime

  AccountType* {.pure.} = enum
    Generated = "generated",
    Key       = "key",
    Seed      = "seed",
    Watch     = "watch"

const STORAGE_ON_DEVICE* = "This device"

proc createAccount*(db: DbConn, account: Account): DbResult[void] =

  try:

    var tblAccounts: Account
    let query = fmt"""
      INSERT OR REPLACE INTO  {tblAccounts.tableName} (
                              {tblAccounts.address.columnName},
                              {tblAccounts.wallet.columnName},
                              {tblAccounts.chat.columnName},
                              {tblAccounts.`type`.columnName},
                              {tblAccounts.storage.columnName},
                              {tblAccounts.path.columnName},
                              {tblAccounts.publicKey.columnName},
                              {tblAccounts.name.columnName},
                              {tblAccounts.color.columnName},
                              {tblAccounts.createdAt.columnName},
                              {tblAccounts.updatedAt.columnName})
      VALUES                  (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"""

    let now = now()
    db.exec(query, account.address, account.wallet, account.chat,
      account.`type`, account.storage, account.path, account.publicKey,
      account.name, account.color, now, now)
    ok()

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc deleteAccount*(db: DbConn, address: Address): DbResult[void] =

  try:

    var tblAccounts: Account
    let query = fmt"""DELETE FROM {tblAccounts.tableName}
                      WHERE       {tblAccounts.address.columnName} = ?"""

    db.exec(query, address)
    ok()

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc getWalletAccount*(db: DbConn, address: Address): DbResult[Option[Account]]
  {.raises: [AssertionError, Defect].} =

  try:

    var tblAccounts: Account
    # NOTE: using `WHERE wallet = TRUE` is not necessarily valid due to the way
    # status-go enforces only one account to have wallet = TRUE (using a unique
    # constraint in the db)
    let query = fmt"""SELECT    {tblAccounts.address.columnName},
                                {tblAccounts.wallet.columnName},
                                {tblAccounts.chat.columnName},
                                {tblAccounts.`type`.columnName},
                                {tblAccounts.storage.columnName},
                                {tblAccounts.path.columnName},
                                {tblAccounts.publicKey.columnName},
                                {tblAccounts.name.columnName},
                                {tblAccounts.color.columnName},
                                {tblAccounts.createdAt.columnName},
                                {tblAccounts.updatedAt.columnName}
                      FROM      {tblAccounts.tableName}
                      WHERE     {tblAccounts.address.columnName} = '{address}'
                                AND {tblAccounts.chat.columnName} = FALSE"""
    ok db.one(Account, query)

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc deleteWalletAccount*(db: DbConn, address: Address):
  DbResult[Option[Account]] =

  try:

    var tblAccounts: Account
    let account = ?db.getWalletAccount(address)
    if account.isSome:
      let query = fmt"""DELETE FROM {tblAccounts.tableName}
                        WHERE       {tblAccounts.address.columnName} = ?
                                    AND {tblAccounts.wallet.columnName} = FALSE"""
      # NOTE: Prevent deletion of the default created account.
      # We're relying on the default wallet account being the only account that
      # has wallet = TRUE. There is a unique DB constraint that enforces this.

      db.exec(query, address)
    ok account

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc getAccounts*(db: DbConn): DbResult[seq[Account]] =

  try:

    var tblAccounts: Account
    let query = fmt"""SELECT    {tblAccounts.address.columnName},
                                {tblAccounts.wallet.columnName},
                                {tblAccounts.chat.columnName},
                                {tblAccounts.`type`.columnName},
                                {tblAccounts.storage.columnName},
                                {tblAccounts.path.columnName},
                                {tblAccounts.publicKey.columnName},
                                {tblAccounts.name.columnName},
                                {tblAccounts.color.columnName},
                                {tblAccounts.createdAt.columnName},
                                {tblAccounts.updatedAt.columnName}
                      FROM      {tblAccounts.tableName}
                      ORDER BY  {tblAccounts.createdAt.columnName} ASC"""
    ok db.all(Account, query)

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc getChatAccount*(db: DbConn): DbResult[Account] =

  try:

    var tblAccounts: Account
    let query = fmt"""SELECT    {tblAccounts.address.columnName},
                                {tblAccounts.wallet.columnName},
                                {tblAccounts.chat.columnName},
                                {tblAccounts.`type`.columnName},
                                {tblAccounts.storage.columnName},
                                {tblAccounts.path.columnName},
                                {tblAccounts.publicKey.columnName},
                                {tblAccounts.name.columnName},
                                {tblAccounts.color.columnName},
                                {tblAccounts.createdAt.columnName},
                                {tblAccounts.updatedAt.columnName}
                      FROM      {tblAccounts.tableName}
                      WHERE     {tblAccounts.chat.columnName} = TRUE"""
    ok db.one(Account, query).get

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc getWalletAccounts*(db: DbConn): DbResult[seq[Account]] =

  try:

    # NOTE: using `WHERE wallet = TRUE` is not necessarily valid due to the way
    # status-go enforces only one account to have wallet = TRUE (using a unique
    # constraint in the db)
    var tblAccounts: Account
    let query = fmt"""SELECT    {tblAccounts.address.columnName},
                                {tblAccounts.wallet.columnName},
                                {tblAccounts.chat.columnName},
                                {tblAccounts.`type`.columnName},
                                {tblAccounts.storage.columnName},
                                {tblAccounts.path.columnName},
                                {tblAccounts.publicKey.columnName},
                                {tblAccounts.name.columnName},
                                {tblAccounts.color.columnName},
                                {tblAccounts.createdAt.columnName},
                                {tblAccounts.updatedAt.columnName}
                      FROM      {tblAccounts.tableName}
                      WHERE     {tblAccounts.chat.columnName} = FALSE
                      ORDER BY  {tblAccounts.createdAt.columnName} ASC"""
    ok db.all(Account, query)

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc updateAccount*(db: DbConn, account: Account): DbResult[void] =

  try:

    var tblAccounts: Account
    let query = fmt"""UPDATE  {tblAccounts.tableName}
                      SET     {tblAccounts.wallet.columnName} = ?,
                              {tblAccounts.chat.columnName} = ?,
                              {tblAccounts.`type`.columnName} = ?,
                              {tblAccounts.storage.columnName} = ?,
                              {tblAccounts.path.columnName} = ?,
                              {tblAccounts.publicKey.columnName} = ?,
                              {tblAccounts.name.columnName} = ?,
                              {tblAccounts.color.columnName} = ?,
                              {tblAccounts.updatedAt.columnName} = ?
                      WHERE   {tblAccounts.address.columnName}= ?"""

    db.exec(query, account.wallet, account.chat, account.`type`, account.storage,
      account.path, account.publicKey, account.name, account.color, now(),
      account.address)
    ok()

  except SqliteError: err OperationError
  except ValueError: err QueryBuildError
