{.push raises: [Defect].}

import # std libs
  std/[json, options, sequtils, strformat]

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
    networkId* {.serializedFieldName($TokenType.NetworkId), dbColumnName($TokenCol.NetworkId).}: NetworkId
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

    db.exec(query, token.networkId, token.address, token.name, token.symbol,
      token.decimals, token.color)
    ok()
  except SqliteError: err OperationError

proc deleteCustomToken*(db: DbConn, address: Address, networkId: NetworkId):
  DbResult[void] =

  try:
    var token: Token
    const query = fmt"""DELETE FROM   {token.tableName}
                        WHERE         {token.address.columnName} = ? AND
                                      {token.networkId.columnName} = ?"""
    db.exec(query, address, networkId)
    ok()
  except SqliteError: err OperationError

proc getCustomToken*(db: DbConn, symbol: string, networkId: NetworkId):
  DbResult[Option[Token]] =

  try:
    var token: Token
    const query = fmt"""SELECT      *
                        FROM        {token.tableName}
                        WHERE       {token.symbol.columnName} = ? AND
                                    {token.networkId.columnName} = ?
                        LIMIT 1"""
    ok db.one(Token, query, symbol, networkId)
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc getCustomTokens*(db: DbConn, networkId: NetworkId): DbResult[seq[Token]] =

  try:
    var token: Token
    const query = fmt"""SELECT      *
                        FROM        {token.tableName}
                        WHERE       {token.networkId.columnName} = ?
                        ORDER BY    {token.symbol.columnName}"""
    ok db.all(Token, query, networkId)
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc getSntToken*(db: DbConn, networkId: NetworkId): DbResult[Option[Token]] =
  let sntNets = @[NetworkId.Mainnet, NetworkId.XDai]
  let symbol = if sntNets.contains(networkId): "SNT" else: "STT"
  db.getCustomToken(symbol, networkId)
