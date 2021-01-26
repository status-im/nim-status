import # nim libs
  json, options, strutils, strformat
import # vendor libs
  web3/conversions as web3_conversions, web3/ethtypes,
  sqlcipher, json_serialization, json_serialization/[reader, writer, lexer],
  stew/byteutils

type
  PendingTxType* {.pure.} = enum
    NetworkId = "networkId",
    TransactionHash = "transactionHash",
    BlkNumber = "blkNumber",
    FromAddress = "fromAddress",
    ToAddress = "toAddress",
    TxType = "txType",
    Data = "data"

  PendingTxCol* {.pure.} = enum
    NetworkId = "network_id",
    TransactionHash = "transaction_hash",
    BlkNumber = "blk_number",
    FromAddress = "from_address",
    ToAddress = "to_address",
    TxType = "type",
    Data = "data"

  PendingTx* {.dbTableName("pending_transactions").} = object
    networkId* {.serializedFieldName($PendingTxType.NetworkId), dbColumnName($PendingTxCol.NetworkId).}: uint
    transactionHash* {.serializedFieldName($PendingTxType.TransactionHash), dbColumnName($PendingTxCol.TransactionHash).}: string
    blkNumber* {.serializedFieldName($PendingTxType.BlkNumber), dbColumnName($PendingTxCol.BlkNumber).}: int
    fromAddress* {.serializedFieldName($PendingTxType.FromAddress), dbColumnName($PendingTxCol.FromAddress).}: string
    toAddress* {.serializedFieldName($PendingTxType.ToAddress), dbColumnName($PendingTxCol.ToAddress).}: string
    txType* {.serializedFieldName($PendingTxType.TxType), dbColumnName($PendingTxCol.TxType).}: string
    data* {.serializedFieldName($PendingTxType.Data), dbColumnName($PendingTxCol.Data).}: string


proc getPendingTxs*(db: DbConn, networkId: int): seq[PendingTx] = 
  var pendingTx: PendingTx
  let query = fmt"""SELECT {pendingTx.networkId.columnName}, {pendingTx.transactionHash.columnName}, {pendingTx.blkNumber.columnName}, {pendingTx.fromAddress.columnName}, {pendingTx.toAddress.columnName}, {pendingTx.txType.columnName}, {pendingTx.data.columnName} FROM {pendingTx.tableName} WHERE {pendingTx.networkId.columnName} = ?"""
  result = db.all(PendingTx, query, networkId)

proc getPendingOutboundTxsByAddress*(db: DbConn, networkId: int, address: string): seq[PendingTx] = 
  var pendingTx: PendingTx
  let query = fmt"""SELECT {pendingTx.networkId.columnName}, {pendingTx.transactionHash.columnName}, {pendingTx.blkNumber.columnName}, {pendingTx.fromAddress.columnName}, {pendingTx.toAddress.columnName}, {pendingTx.txType.columnName}, {pendingTx.data.columnName} FROM {pendingTx.tableName} WHERE {pendingTx.networkId.columnName} = ? AND {pendingTx.fromAddress.columnName} = ?"""
  result = db.all(PendingTx, query, networkId, address)

proc savePendingTx*(db: DbConn, tx: PendingTx) = 
  var pendingTx: PendingTx
  let query = fmt"""
    INSERT OR REPLACE INTO {pendingTx.tableName} (
      {$PendingTxCol.NetworkId},
      {$PendingTxCol.TransactionHash}, 
      {$PendingTxCol.BlkNumber}, 
      {$PendingTxCol.FromAddress}, 
      {$PendingTxCol.ToAddress}, 
      {$PendingTxCol.TxType}, 
      {$PendingTxCol.Data}) 
    VALUES (?, ?, ?, ?, ?, ?, ?)
    """

  db.exec(query, 
    tx.networkId,
    tx.transactionHash,
    tx.blkNumber,
    tx.fromAddress,
    tx.toAddress,
    tx.txType,
    tx.data)

proc deletePendingTx*(db: DbConn, transactionHash: string) =
  var pendingTx: PendingTx
  let query = fmt"""DELETE FROM {pendingTx.tableName} WHERE {pendingTx.transactionHash.columnName} = ?"""
  db.exec(query, transactionHash)
