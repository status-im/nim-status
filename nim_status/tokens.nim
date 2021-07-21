import # nim libs
  json, options, strutils, strformat

import # vendor libs
  web3/ethtypes,
  sqlcipher, json_serialization,
  json_serialization/[reader, writer, lexer]

import # nim-status libs
  conversions

type 
  TokenError* = object of CatchableError

  TokenType* {.pure.} = enum
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
    address* {.serializedFieldName($TokenType.Address), dbColumnName($TokenCol.Address).}: Address
    name* {.serializedFieldName($TokenType.Name), dbColumnName($TokenCol.Name).}: string
    symbol* {.serializedFieldName($TokenType.Symbol), dbColumnName($TokenCol.Symbol).}: string
    color* {.serializedFieldName($TokenType.Color), dbColumnName($TokenCol.Color).}: string
    decimals* {.serializedFieldName($TokenType.Decimals), dbColumnName($TokenCol.Decimals).}: uint

proc addCustomToken*(db: DbConn, token: Token) =
  const query = fmt"""INSERT OR REPLACE INTO TOKENS ({$TokenCol.NetworkId}, {$TokenCol.Address}, {$TokenCol.Name}, {$TokenCol.Symbol}, {$TokenCol.Decimals}, {$TokenCol.Color}) VALUES (?, ?, ?, ?, ?, ?)"""
  # TODO: get network id
  db.exec(query, 1, $token.address, token.name, token.symbol, token.decimals, token.color)

proc getCustomTokens*(db: DbConn): seq[Token] =
  var token: Token
  const query = fmt"""SELECT * FROM {token.tableName}"""
  result = db.all(Token, query)

proc deleteCustomToken*(db: DbConn, address: Address) =
  var token: Token
  const query = fmt"""DELETE FROM {token.tableName} WHERE {$TokenCol.Address} = ?"""
  db.exec(query, $address)

