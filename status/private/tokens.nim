{.push raises: [Defect].}

import # std libs
  std/[json, options, strformat]

import # vendor libs
  json_serialization,
  json_serialization/[reader, writer],
  sqlcipher, web3/ethtypes

import # status modules
  ./common, ./conversions

type
  TokenType* {.pure.} = enum
    NetworkId = "networkId",
    Address = "address",
    Name = "name",
    Symbol = "symbol",
    Color = "color",
    Decimals = "decimals"

  TokenCol* {.pure.} = enum
    NetworkId = "network_id",
    Address = "address",
    Name = "name",
    Symbol = "symbol",
    Decimals = "decimals",
    Color = "color"

  Token* {.dbTableName("tokens").} = object
    networkId* {.serializedFieldName($TokenType.NetworkId), dbColumnName($TokenCol.NetworkId).}: uint
    address* {.serializedFieldName($TokenType.Address), dbColumnName($TokenCol.Address).}: Address
    name* {.serializedFieldName($TokenType.Name), dbColumnName($TokenCol.Name).}: string
    symbol* {.serializedFieldName($TokenType.Symbol), dbColumnName($TokenCol.Symbol).}: string
    color* {.serializedFieldName($TokenType.Color), dbColumnName($TokenCol.Color).}: string
    decimals* {.serializedFieldName($TokenType.Decimals), dbColumnName($TokenCol.Decimals).}: uint

proc addCustomToken*(db: DbConn, token: Token): DbResult[void] =

  try:
    var tblToken: Token
    const query = fmt"""INSERT OR REPLACE INTO  {tblToken.tableName} (
                                                  {TokenCol.NetworkId},
                                                  {TokenCol.Address},
                                                  {TokenCol.Name},
                                                  {TokenCol.Symbol},
                                                  {TokenCol.Decimals},
                                                  {TokenCol.Color}
                                                )
                        VALUES                  (?, ?, ?, ?, ?, ?)"""
    # TODO: get network id
    db.exec(query, 1, $token.address, token.name, token.symbol, token.decimals,
      token.color)
    ok()
  except SqliteError: err OperationError

proc getCustomTokens*(db: DbConn): DbResult[seq[Token]] =

  try:
    var token: Token
    const query = fmt"""SELECT      *
                        FROM        {token.tableName}
                        ORDER BY    {token.symbol.columnName},
                                    {token.networkId.columnName}"""
    ok db.all(Token, query)
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc deleteCustomToken*(db: DbConn, address: Address): DbResult[void] =

  try:
    var token: Token
    const query = fmt"""DELETE FROM   {token.tableName}
                        WHERE         {TokenCol.Address} = ?"""
    db.exec(query, $address)
    ok()
  except SqliteError: err OperationError
