{.push raises: [Defect].}

import # std libs
  std/[json, os, rlocks, sequtils, sets, strformat, strutils, tables]

import # vendor libs
  chronos, json_rpc/client, json_serialization, sqlcipher, stew/byteutils, web3

from nimcrypto import digest, keccak_256

import # status modules
  ./callrpc, ./common, ./conversions, ./tx_history/types, ./util

type
  TxHistoryError* = enum
    DbWriteError      = "txhistory: error writing to db"
    FetchDbDataError  = "txhistory: error fetching db data"
    LogKeyError       = "txhistory: error getting log for specified key"
    ParseHexDataError = "txhistory: error parsing data as hex"
    ParseJsonError    = "txhistory: error parsing json"
    RpcError          = "txhistory: error calling rpc method"
    UnknownError      = "txhistory: unknown error occurred"

  TxHistoryResult*[T] = Result[T, TxHistoryError]

const txsPerPage = 20
const ethTransferType = "eth"
const erc20TransferType = "erc20"

var web3Obj {.threadvar.}: Web3
var db {.threadvar.}: DbConn

proc setWeb3Obj*(web3: Web3) =
  web3Obj = web3

proc setDbConn*(dbConn: DbConn) =
  db = dbConn

# blockNumber can be either "earliest", "latest", "pending", or hex-encoding int
proc getValueForBlock*(address: types.Address, blockNumber: string,
  methodName: RemoteMethod): Future[TxHistoryResult[int]] {.async.} =

  # try:
  let
    jsonNode =  try: parseJson(fmt"""["{address}", "{blockNumber}"]""")
                except Exception:
                  return err ParseJsonError
    respResult = await callRpc(web3Obj, methodName, jsonNode)
  if respResult.isErr: return err RpcError
  let hex = fromHex[int](respResult.get.getStr)
  return ok hex

proc getLastBlockNumber*(): Future[TxHistoryResult[int]] {.async.} =

  # try:
  let
    jsonNode =  try: parseJSON("""[]""")
                except Exception:
                  return err ParseJsonError
    respResult = await callRpc(web3Obj, RemoteMethod.eth_blockNumber, jsonNode)
  if respResult.isErr: return err RpcError
  let hex = fromHex[int](respResult.get.getStr)
  return ok hex

# Find lowest block number for which a condition
# procPtr(address, blockNumber) >= targetValue holds
proc findLowestBlockNumber*(address: types.Address, blockRange: BlockRange,
  methodName: RemoteMethod, targetValue: int): Future[TxHistoryResult[int]]
  {.async.} =

  var fromBlock = blockRange[0]
  var toBlock = blockRange[1]
  var blockNumber = fromBlock
  while toBlock != fromBlock:
    blockNumber = (toBlock + fromBlock) /% 2
    let blockNumberHex: string = intToHex(blockNumber)
    let valueResult = await getValueForBlock(address, blockNumberHex, methodName)
    if valueResult.isErr: return err valueResult.error
    if valueResult.get >= targetValue:
      toBlock = blockNumber
    else:
      fromBlock = blockNumber + 1

  return ok fromBlock

# Find a block range with minimum txsPerPage transactions
proc txBinarySearch*(address: types.Address, toBlock: int):
  Future[TxHistoryResult[BlockRange]] {.async.} =

  # try:
  let totalTxCountResult = await getValueForBlock(address, intToHex(toBlock),
    RemoteMethod.eth_getTransactionCount)
  if totalTxCountResult.isErr: return err totalTxCountResult.error
  let totalTxCount = totalTxCountResult.get
  if totalTxCount == 0:
    return ok [0, 0]

  var leftBlock = 0
  if totalTxCount > txsPerPage:
    # Find lower bound (number of the block containing lowerTxBound txs
    # This means finding lowest block number containing lowerTxBound txs
    let lowerTxBound = totalTxCount - 19
    let leftBlockResult = await findLowestBlockNumber(address, [0, toBlock],
      RemoteMethod.eth_getTransactionCount, lowerTxBound)
    if leftBlockResult.isErr: return err leftBlockResult.error
    leftBlock = leftBlockResult.get
  #else:
    # No need to restrict block range, as there can be incoming transactions
    # anywhere inside the whole range

  return ok [leftBlock, toBlock]


# First, we find a lowest block number with balance
# equal to that of toBlock
# Then we check if there were any outgoing txs between it and the last block,
# as it could've happened that several txs balanced themselves out
proc findBlockWithBalanceChange(address: types.Address, blockRange: BlockRange):
  Future[TxHistoryResult[int]] {.async.} =

  # try:
  var fromBlock = blockRange[0]
  var toBlock = blockRange[1]
  var blockNumber = toBlock
  let targetBalanceResult = await getValueForBlock(address, intToHex(toBlock),
    RemoteMethod.eth_getBalance)
  if targetBalanceResult.isErr: return err targetBalanceResult.error
  let targetBalance = targetBalanceResult.get
  var blockNumberResult = await findLowestBlockNumber(address,
    [fromBlock, toBlock], RemoteMethod.eth_getBalance, targetBalance)
  if blockNumberResult.isErr: return err blockNumberResult.error
  blockNumber = blockNumberResult.get

  # Check if there were no txs in [blockNumber, toBlock]
  # Note that eth_getTransactionCount only counts outgoing transactions
  let txCount1Result = await getValueForBlock(address, intToHex(blockNumber),
    RemoteMethod.eth_getTransactionCount)
  if txCount1Result.isErr: return err txCount1Result.error
  let txCount1 = txCount1Result.get
  let txCount2Result = await getValueForBlock(address, intToHex(toBlock),
    RemoteMethod.eth_getTransactionCount)
  if txCount2Result.isErr: return err txCount2Result.error
  let txCount2 = txCount2Result.get
  if txCount1 == txCount2:
    # No txs occurred in between [blockNumber, toBlock]
    return ok blockNumber
  else:
    # At least several txs occurred, so we find the number
    # of the lowest block containing txCount2
    blockNumberResult = await findLowestBlockNumber(address, [fromBlock, toBlock],
      RemoteMethod.eth_getTransactionCount, txCount2)
    if blockNumberResult.isErr: return err blockNumberResult.error
    blockNumber = blockNumberResult.get
    let balance = await getValueForBlock(address, intToHex(blockNumber),
      RemoteMethod.eth_getBalance)
    if balance.isErr: return err balance.error
    if balance.get == targetBalance:
      # This was the tx setting targetbalance
      return ok blockNumber
    else:
      # This means there must have been an incoming tx inside [blockNumber,
      # toBlock]
      let lowestBlockResult = await findLowestBlockNumber(address,
        [blockNumber, toBlock], RemoteMethod.eth_getBalance, targetBalance)
      if lowestBlockResult.isErr: return err lowestBlockResult.error
      return lowestBlockResult


# We need to find exact block numbers containing balance changes
proc balanceBinarySearch*(address: types.Address, blockRange: BlockRange):
  Future[TxHistoryResult[BlockSeq]] {.async.} =

  var blockNumbers: BlockSeq = @[]
  var fromBlock = blockRange[0]
  var toBlock = blockRange[1]
  while fromBlock < toBlock and len(blockNumbers) < txsPerPage:
    let blockNumberResult = await findBlockWithBalanceChange(address,
      [fromBlock, toBlock])
    if blockNumberResult.isErr: return err blockNumberResult.error
    let blockNumber = blockNumberResult.get
    blockNumbers.add(blockNumber)

    toBlock = blockNumber - 1

  return ok blockNumbers

proc filterTxsForAddress*(address: types.Address, blockNumbers: BlockSeq,
  txToData: var TransferMap): Future[TxHistoryResult[void]] {.async.} =

  # try:
  for n in items(blockNumbers):
    let
      blockNumber = intToHex(n)
      jsonNode =  try: parseJSON(fmt"""["{blockNumber}", true]""")
                  except Exception as e:
                    return err ParseJsonError
      respResult = await callRpc(web3Obj, RemoteMethod.eth_getBlockByNumber,
        jsonNode)
    if respResult.isErr: return err RpcError
    let
      resp = respResult.get
      blockHash = resp["hash"].getStr
      timestamp = fromHex[int](resp["timestamp"].getStr)
    for tx in items(resp["transactions"]):
      if cmpIgnoreCase(tx["from"].getStr, address) == 0 or
        cmpIgnoreCase(tx["to"].getStr, address) == 0:
        let txHash = tx["hash"].getStr
        let trView = Transfer(
          txType: TxType.eth,
          address: address,
          blockNumber: n,
          blockHash: blockHash,
          timestamp: timestamp,
          txHash: txHash)
        txToData[txHash] = trView
  return ok()


# Find blocks with balance changes and extract tx hashes from info
# fetched via eth_getBlockByNumber
proc fetchEthTxHashes(address: types.Address, txBlockRange: BlockRange,
  txToData: var TransferMap): Future[TxHistoryResult[void]] {.async.} =

  # Find block numbers containing balance changes
  let blockNumbersResult = await balanceBinarySearch(address,
    txBlockRange)
  if blockNumbersResult.isErr: return err blockNumbersResult.error
  let blockNumbers = blockNumbersResult.get

  # Get block info and extract txs pertaining to given address
  return await filterTxsForAddress(address, blockNumbers, txToData)

# Parse log entry in order to fetch fromAddr, toAddr, and value
proc parseLog(log: JsonNode): TxHistoryResult[tuple[fromAddr: types.Address,
  toAddr: types.Address, value: int]] {.raises: [].} =

  const errorMsg = "Error parsing log"

  try:
    if len(log["topics"].getElems) < 3:
      echo "not enough topics for erc20 transfer", log["topics"]
      return

    let topic2 = log["topics"].getElems[1].getStr
    if len(topic2) != 66:
      echo "second topic is not padded to 32 byte address", topic2
      return

    let topic3 = log["topics"].getElems[2].getStr
    if len(topic3) != 66:
      echo "third topic is not padded to 32 byte address", topic3
      return

    let data = log["data"].getStr
    if len(data) != 66:
      echo "data is not padded to 32 byts big int", data
      return

    let value = fromHex[int](data)
    let fromAddr = "0x" & topic2[26..<66]
    let toAddr = "0x" & topic3[26..<66]

    return ok (fromAddr, toAddr, value)
  except KeyError: return err LogKeyError
  except ValueError: return err ParseHexDataError

# We have to invoke eth_getLogs twice for both
# incoming and outgoing ERC-20 transfers
# TODO: check if this {.gcsafe.} is needed!
proc fetchErc20Logs*(address: types.Address, blockRange: BlockRange,
  txToData: var TransferMap): Future[TxHistoryResult[void]] {.async, gcsafe.} =

  try:
    let transferEventSignatureHash = "0x" &
      $keccak_256.digest("Transfer(address,address,uint256)")
    echo "transferEventSignatureHash :", transferEventSignatureHash

    let fromBlock = intToHex(blockRange[0])
    let toBlock = intToHex(blockRange[1])
    echo "fromBlock: ", fromBlock
    let addressPadded = "0x" & '0'.repeat(24) & address[2..<len(address)]
    echo "addressPadded: ", addressPadded
    var jsonNode = parseJson(fmt"""[{{
      "fromBlock": "{fromBlock}",
      "toBlock": "{toBlock}",
      "topics": ["{transferEventSignatureHash}", null, "{addressPadded}"]}}]""")

    let incomingLogsResult = await callRpc(web3Obj, RemoteMethod.eth_getLogs,
      jsonNode)
    if incomingLogsResult.isErr: return err RpcError
    var incomingLogs = incomingLogsResult.get
    #echo "incomingLogs: ", incomingLogs
    jsonNode = parseJson(fmt"""[{{
      "fromBlock": "{fromBlock}",
      "toBlock": "{toBlock}",
      "topics": ["{transferEventSignatureHash}", "{addressPadded}", null]}}]""")

    let outgoingLogsResult = await callRpc(web3Obj, RemoteMethod.eth_getLogs,
      jsonNode)
    if outgoingLogsResult.isErr: return err RpcError
    var outgoingLogs = outgoingLogsResult.get
    #echo "outgoingLogs: ", outgoingLogs

    var logs: seq[JsonNode] = concat(incomingLogs.getElems, outgoingLogs.getElems)
    for obj in logs:
      let txHash = obj["transactionHash"].getStr
      let blockNumber = fromHex[int](obj["blockNumber"].getStr)
      let blockHash = obj["blockHash"].getStr
      let parsedLogResult = parseLog(obj)
      if parsedLogResult.isErr: return err parsedLogResult.error
      let parsedLog = parsedLogResult.get
      let trView = Transfer(
        txType: TxType.erc20,
        address: address,
        blockNumber: blockNumber,
        blockHash: blockHash,
        txHash: txHash,
        fromAddr: parsedLog.fromAddr,
        toAddr: parsedLog.toAddr,
        value: parsedLog.value,
        contract: obj["address"].getStr
        )
      txToData[txHash] = trView
  except Exception as e: # raised by parseJson
    return err ParseJsonError


proc fetchTxDetails*(address: types.Address, txToData: var TransferMap):
  Future[TxHistoryResult[void]] {.async.} =

  # try:
  for tx in txToData.keys:
    let
      jsonNode =  try: parseJSON(fmt"""["{tx}"]""")
                  except Exception as e:
                    return err ParseJsonError
      txInfoResult = await callRpc(web3Obj, RemoteMethod.eth_getTransactionByHash,
        jsonNode)
    if txInfoResult.isErr: return err RpcError
    let
      txInfo = txInfoResult.get
      txReceiptResult = await callRpc(web3Obj,
        RemoteMethod.eth_getTransactionReceipt, jsonNode)
    if txReceiptResult.isErr: return err RpcError
    let txReceipt = txReceiptResult.get

    echo "fetchTxDetails txInfo: ", txInfo

    echo "fetchTxDetails txReceipt: ", txReceipt

    var trView = txToData[tx]
    trView.gasPrice = fromHex[int](txInfo["gasPrice"].getStr)
    trView.gasLimit = fromHex[int](txInfo["gas"].getStr)
    trView.gasUsed = fromHex[int](txReceipt["gasUsed"].getStr)
    trView.nonce = fromHex[int](txInfo["nonce"].getStr)
    trView.txStatus = fromHex[int](txReceipt["status"].getStr)
    trView.input = txInfo["input"].getStr
    if trView.txType == eth:
      trView.contract = txReceipt["contractAddress"].getStr
      trView.value = fromHex[int](txInfo["value"].getStr)
      trView.fromAddr = txInfo["from"].getStr
      trView.toAddr = txInfo["to"].getStr

    echo "gasLimit, ", fromHex[int](txInfo["gas"].getStr)
    echo "trView.gasLimit, ", trView.gasLimit
    txToData[tx] = trView


proc fetchDbData*(address: types.Address): DbResult[TxDbData] =

  try:
    var
      dbData = TxDbData()
      tblTxHistory: Transfer
      tblTxHistoryInfo: TransferInfo

    let query = fmt"""SELECT  *
                      FROM    {tblTxHistory.tableName}
                      WHERE   {TransferCol.Address}=?"""

    let infoQuery = fmt"""SELECT  *
                          FROM    {tblTxHistoryInfo.tableName}
                          WHERE   {TransferInfoCol.Address}=?"""
    let dbResult = db.one(TransferInfo, infoQuery, address)
    if dbResult.isSome():
      dbData.info = dbResult.get()

    let transfer = db.one(query, address)
    echo "transfers: ", transfer.get().values()
    let transfers = db.all(Transfer, query, address)
    if len(transfers) > 0:
      for t in items(transfers):
        dbData.txToData.add(t.txHash, t)

    ok dbData
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc saveTransferInfo*(transferInfo: TransferInfo): DbResult[void] {.raises:
  [].} =

  try:
    var tblTxHistoryInfo: TransferInfo
    let query = fmt"""
                  INSERT INTO {tblTxHistoryInfo.tableName} (
                                {TransferInfoCol.Address},
                                {TransferInfoCol.Balance},
                                {TransferInfoCol.BlockNumber},
                                {TransferInfoCol.TxCount}
                              )
                  VALUES      (?, ?, ?, ?)
                  """
    db.exec(query,
            transferInfo.address,
            transferInfo.balance,
            transferInfo.blockNumber,
            transferInfo.txCount)
    ok()
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc saveTransfer*(transfer: Transfer): DbResult[void] {.raises: [].} =

  try:
    var txHistory: Transfer
    let query = fmt"""
                  INSERT INTO   {txHistory.tableName} (
                                  {TransferCol.Id},
                                  {TransferCol.TxType},
                                  {TransferCol.Address},
                                  {TransferCol.BlockNumber},
                                  {TransferCol.BlockHash},
                                  {TransferCol.Timestamp},
                                  {TransferCol.GasPrice},
                                  {TransferCol.GasLimit},
                                  {TransferCol.GasUsed},
                                  {TransferCol.Nonce},
                                  {TransferCol.TxStatus},
                                  {TransferCol.Input},
                                  {TransferCol.TxHash},
                                  {TransferCol.Value},
                                  {TransferCol.FromAddr},
                                  {TransferCol.ToAddr},
                                  {TransferCol.Contract},
                                  {TransferCol.NetworkID}
                                )
                  VALUES        (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                                ?, ?, ?)"""
    db.exec(query,
            transfer.id,
            transfer.txType,
            transfer.address,
            transfer.blockNumber,
            transfer.blockHash,
            transfer.timestamp,
            transfer.gasPrice,
            transfer.gasLimit,
            transfer.gasUsed,
            transfer.nonce,
            transfer.txStatus,
            transfer.input,
            transfer.txHash,
            transfer.value,
            transfer.fromAddr,
            transfer.toAddr,
            transfer.contract,
            transfer.networkID)
    ok()
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

proc writeToDb(dbData: TxDbData): DbResult[void] {.raises: [].} =

  try:
    echo "writeToDb"
    ?saveTransferInfo(dbData.info)
    for transfer in dbData.txToData.values:
      ?saveTransfer(transfer)

    ok()
  except SqliteError: err OperationError
  except ValueError: err QueryBuildError

# Used for passing address strings to scheduler thread
# bool parameter stands for addedOrRemoved flag
var chan: Channel[tuple[address: string, addOrRemove: bool]]

# Locks when tx data are being fetched in schedulerProc
var fetchLock: RLock


let schedulerInterval = 2 * 60 * 1000

# Main history fetching proc
proc scheduler(): Future[TxHistoryResult[void]] {.async.} =
  try:
    while true:
      withRLock(fetchLock):
        var addresses = initHashSet[string]()

        # Fetch addresses from the channel
        while chan.peek() > 0:

          let t = chan.recv()
          let address = t[0]
          let addOrRemove: bool = t[1]
          if addOrRemove:
            addresses.incl(address)
          else:
            addresses.excl(address)


        # Update history for each address
        for address in items(addresses):
          let dbDataResult = fetchDbData(address)
          if dbDataResult.isErr: return err FetchDbDataError
          let dbData = dbDataResult.get

          let dbBlockNumber = dbData.info.blockNumber
          let dbTxCount = dbData.info.txCount
          let dbBalance = dbData.info.balance

          # If this is an initial wallet scan, all of [dbBlockNumber, dbTxCount, dbBalance]
          # will be zero
          let lastBlockNumberResult = await getLastBlockNumber()
          if lastBlockNumberResult.isErr: return err lastBlockNumberResult.error
          var lastBlockNumber = lastBlockNumberResult.get
          if lastBlockNumber > dbBlockNumber:
            # There are new blocks, check if outgoing tx count or balance changed
            let txCountResult = await getValueForBlock(address,
              intToHex(lastBlockNumber), RemoteMethod.eth_getTransactionCount)
            if txCountResult.isErr: return err txCountResult.error
            let txCount = txCountResult.get
            let balanceResult = await getValueForBlock(address,
              intToHex(lastBlockNumber), RemoteMethod.eth_getBalance)
            if balanceResult.isErr: return err balanceResult.error
            let balance = balanceResult.get

            var txBlockRange: BlockRange
            if dbBlockNumber == 0:
              let txBlockRangeResult = await txBinarySearch(address,
                lastBlockNumber)
              if txBlockRangeResult.isErr: return err txBlockRangeResult.error
              txBlockRange = txBlockRangeResult.get
            else:
              txBlockRange = [dbBlockNumber + 1, lastBlockNumber]
            var txToData = TransferMap()

            # Only fetch eth transfers if tx count or balance changed
            if dbTxCount != txCount or dbBalance != balance:
              let fetchTxHashes = await fetchEthTxHashes(address,
                txBlockRange, txToData)
              if fetchTxHashes.isErr: return err fetchTxHashes.error

            # ERC-20 logs should be checked anyways
            let fetchLogs = await fetchErc20Logs(address, txBlockRange, txToData)
            if fetchLogs.isErr: return err fetchLogs.error

            if len(txToData) > 0:
              let txDetails = await fetchTxDetails(address, txToData)
              if txDetails.isErr: return err txDetails.error

            let transferInfo = TransferInfo(
              address: address,
              balance: balance,
              blockNumber: lastBlockNumber,
              txCount: txCount)

            let writeResult = writeToDb(TxDbData(info: transferInfo,
              txToData: txToData))
            if writeResult.isErr: return err DbWriteError

      await sleepAsync(schedulerInterval)
      return ok()

  except Exception as e: # raised by channel.recv()
    return err UnknownError

proc schedulerProc() {.thread, raises: [Defect,
  CatchableError].} =

  let schedulerResult = waitFor scheduler()
  if schedulerResult.isErr:
    raise newException(CatchableError, "Error executing scheduler")

proc fetchTxHistory*(address: types.Address, toBlock: int):
  Future[TxHistoryResult[TransferMap]] {.async.} =

  # try:
  var txToData = TransferMap()

  # Find block range that we will search for balance changes
  let txBlockRangeResult = await txBinarySearch(address, toBlock)
  if txBlockRangeResult.isErr: return err txBlockRangeResult.error
  let txBlockRange = txBlockRangeResult.get
  if txBlockRange == [0, 0]:
    # No txs found
    return ok txToData

  let fetchTxHashes = await fetchEthTxHashes(address, txBlockRange, txToData)
  if fetchTxHashes.isErr: return err fetchTxHashes.error
  let fetchLogs = await fetchErc20Logs(address, txBlockRange, txToData)
  if fetchLogs.isErr: return err fetchLogs.error

  let fetchTxDetails = await fetchTxDetails(address, txToData)
  if fetchTxDetails.isErr: return err fetchTxDetails.error
  for transfer in txToData.values:
    let saveResult = saveTransfer(transfer)
    if saveResult.isErr: return err DbWriteError

  return ok txToData

proc getTransfersByAddress*(address: types.Address, toBlock: int):
  Future[TxHistoryResult[TransferMap]] {.async.} =

  # try:
  var dbDataResult = fetchDbData(address)
  if dbDataResult.isErr: return err FetchDbDataError
  var dbData = dbDataResult.get
  if dbData.info.blockNumber == 0:
    # Nothing has been fetched yet, wait for
    # schedulerProc to fetch it
    withRLock(fetchLock):
      dbDataResult = fetchDbData(address)
      if dbDataResult.isErr: return err FetchDbDataError
      dbData = dbDataResult.get
  elif dbData.info.blockNumber > toBlock:
    # Fetch a previous range
    let transferMapResult = await fetchTxHistory(address, toBlock)
    if transferMapResult.isErr: return err transferMapResult.error
    let transferMap = transferMapResult.get
    dbData.txToData = transferMap

  return ok dbData.txToData

proc init*(addresses: seq[types.Address]): TxHistoryResult[void] =

  const errorMsg = "Error initializing the transaction history scheduler"

  try:
    initRLock(fetchLock)

    # Inititialize the channel and send account addresses
    chan.open()
    for a in addresses:
      chan.send((a, true))

    # Run the scheduler thread
    var schedulerThread: Thread[void]
    createThread(schedulerThread, schedulerProc)
    ok()
  except CatchableError: err UnknownError
  except Exception as e: # raised by channel.send()
    err UnknownError
