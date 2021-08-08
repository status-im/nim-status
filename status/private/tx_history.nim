{.push raises: [Defect].}

import # std libs
  std/[json, os, rlocks, sequtils, sets, strformat, strutils, tables]

import # vendor libs
  json_rpc/client, json_serialization,
  sqlcipher, stew/byteutils, web3
from nimcrypto import digest, keccak_256

import # status modules
  ./callrpc, ./common, ./conversions, ./tx_history/types

type
  TxHistoryError* = object of StatusError
  TxHistoryDbError* = object of StatusError

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
  methodName: RemoteMethod): int {.raises: [Defect, TxHistoryError].} =

  const errorMsg = "Error getting value for block"
  try:
    let
      jsonNode =  try: parseJson(fmt"""["{address}", "{blockNumber}"]""")
                  except Exception as e:
                    raise (ref TxHistoryError)(parent: e, msg: "Error " &
                      "parsing json with address and block number")
      resp = callRPC(web3Obj, methodName, jsonNode)
    return fromHex[int](resp.getStr)
  except IOError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except OSError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except Web3Error as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)

proc getLastBlockNumber*(): int {.raises: [Defect, TxHistoryError].} =

  const errorMsg = "Error getting value for block"
  try:
    let
      jsonNode =  try: parseJSON("""[]""")
                  except Exception as e:
                    raise (ref TxHistoryError)(parent: e, msg: "Error " &
                      "parsing json")
      resp = callRPC(web3Obj, RemoteMethod.eth_blockNumber, jsonNode)
    return fromHex[int](resp.getStr)
  except IOError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except OSError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except Web3Error as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)

# Find lowest block number for which a condition
# procPtr(address, blockNumber) >= targetValue holds
proc findLowestBlockNumber*(address: types.Address,
  blockRange: BlockRange, methodName: RemoteMethod, targetValue: int): int
  {.raises: [Defect, TxHistoryError].} =

  const errorMsg = "Error finding lowest block number"
  try:
    var fromBlock = blockRange[0]
    var toBlock = blockRange[1]
    var blockNumber = fromBlock
    while toBlock != fromBlock:
      blockNumber = (toBlock + fromBlock) /% 2
      let blockNumberHex: string = intToHex(blockNumber)
      let value = getValueForBlock(address, blockNumberHex, methodName)
      if value >= targetValue:
        toBlock = blockNumber
      else:
        fromBlock = blockNumber + 1

    return fromBlock
  except IOError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)

# Find a block range with minimum txsPerPage transactions
proc txBinarySearch*(address: types.Address, toBlock: int): BlockRange {.raises:
  [Defect, TxHistoryError].} =

  try:
    let totalTxCount = getValueForBlock(address, intToHex(toBlock),
      RemoteMethod.eth_getTransactionCount)
    if totalTxCount == 0:
      return [0, 0]

    var leftBlock = 0
    if totalTxCount > txsPerPage:
      # Find lower bound (number of the block containing lowerTxBound txs
      # This means finding lowest block number containing lowerTxBound txs
      let lowerTxBound = totalTxCount - 19
      leftBlock = findLowestBlockNumber(address, [0, toBlock],
                            RemoteMethod.eth_getTransactionCount, lowerTxBound)
    #else:
      # No need to restrict block range, as there can be incoming transactions
      # anywhere inside the whole range

    return [leftBlock, toBlock]
  except TxHistoryError as e:
    raise (ref TxHistoryError)(parent: e, msg: "Error doing transaction " &
      "binary search")


# First, we find a lowest block number with balance
# equal to that of toBlock
# Then we check if there were any outgoing txs between it and the last block,
# as it could've happened that several txs balanced themselves out
proc findBlockWithBalanceChange(address: types.Address, blockRange: BlockRange):
  int {.raises: [Defect, TxHistoryError].} =

  try:
    var fromBlock = blockRange[0]
    var toBlock = blockRange[1]
    var blockNumber = toBlock
    let targetBalance = getValueForBlock(address, intToHex(toBlock),
      RemoteMethod.eth_getBalance)
    blockNumber = findLowestBlockNumber(address, [fromBlock, toBlock],
                          RemoteMethod.eth_getBalance, targetBalance)

    # Check if there were no txs in [blockNumber, toBlock]
    # Note that eth_getTransactionCount only counts outgoing transactions
    let txCount1 = getValueForBlock(address, intToHex(blockNumber),
      RemoteMethod.eth_getTransactionCount)
    let txCount2 = getValueForBlock(address, intToHex(toBlock),
      RemoteMethod.eth_getTransactionCount)
    if txCount1 == txCount2:
      # No txs occurred in between [blockNumber, toBlock]
      result = blockNumber
    else:
      # At least several txs occurred, so we find the number
      # of the lowest block containing txCount2
      blockNumber = findLowestBlockNumber(address, [fromBlock, toBlock],
                          RemoteMethod.eth_getTransactionCount, txCount2)
      let balance = getValueForBlock(address, intToHex(blockNumber),
        RemoteMethod.eth_getBalance)
      if balance == targetBalance:
        # This was the tx setting targetbalance
        result = blockNumber
      else:
        # This means there must have been an incoming tx inside [blockNumber,
        # toBlock]
        result = findLowestBlockNumber(address, [blockNumber, toBlock],
                          RemoteMethod.eth_getBalance, targetBalance)
  except TxHistoryError as e:
    raise (ref TxHistoryError)(parent: e, msg: "Error finding block with " &
      "balance change")


# We need to find exact block numbers containing balance changes
proc balanceBinarySearch*(address: types.Address, blockRange: BlockRange):
  BlockSeq {.raises: [Defect, TxHistoryError].} =

  const errorMsg = "Error finding blocks with balance changes"
  try:
    var blockNumbers: BlockSeq = @[]
    var fromBlock = blockRange[0]
    var toBlock = blockRange[1]
    while fromBlock < toBlock and len(blockNumbers) < txsPerPage:
      let blockNumber = findBlockWithBalanceChange(address, [fromBlock, toBlock])
      blockNumbers.add(blockNumber)

      toBlock = blockNumber - 1

    result = blockNumbers
  except TxHistoryError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)

proc filterTxsForAddress*(address: types.Address, blockNumbers: BlockSeq,
  txToData: var TransferMap) {.raises: [Defect, TxHistoryError].} =

  const errorMsg = "Error filtering transactions by address"
  try:
    for n in items(blockNumbers):
      let
        blockNumber = intToHex(n)
        jsonNode =  try: parseJSON(fmt"""["{blockNumber}", true]""")
                    except Exception as e:
                      raise (ref TxHistoryError)(parent: e, msg: "Error " &
                        "parsing json with block number")
        resp = callRPC(web3Obj, RemoteMethod.eth_getBlockByNumber, jsonNode)
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
  except IOError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except OSError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except Web3Error as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)


# Find blocks with balance changes and extract tx hashes from info
# fetched via eth_getBlockByNumber
proc fetchEthTxHashes(address: types.Address, txBlockRange: BlockRange,
  txToData: var TransferMap) {.raises: [Defect, TxHistoryError].} =

  const errorMsg = "Error fetching transaction hashes"

  try:
    # Find block numbers containing balance changes
    var blockNumbers: BlockSeq = balanceBinarySearch(address, txBlockRange)

    # Get block info and extract txs pertaining to given address
    filterTxsForAddress(address, blockNumbers, txToData)
  except TxHistoryError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)

# Parse log entry in order to fetch fromAddr, toAddr, and value
proc parseLog(log: JsonNode): tuple[fromAddr: types.Address,
  toAddr: types.Address, value: int] {.raises: [TxHistoryError].} =

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

    return (fromAddr, toAddr, value)
  except KeyError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)

# We have to invoke eth_getLogs twice for both
# incoming and outgoing ERC-20 transfers
# TODO: check if this {.gcsafe.} is needed!
proc fetchErc20Logs*(address: types.Address, blockRange: BlockRange,
  txToData: var TransferMap) {.gcsafe, raises: [Defect, TxHistoryError].} =

  const errorMsg = "Error fetching ERC-20 logs"

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

    var incomingLogs = callRPC(web3Obj, RemoteMethod.eth_getLogs, jsonNode)
    #echo "incomingLogs: ", incomingLogs
    jsonNode = parseJson(fmt"""[{{
      "fromBlock": "{fromBlock}",
      "toBlock": "{toBlock}",
      "topics": ["{transferEventSignatureHash}", "{addressPadded}", null]}}]""")

    var outgoingLogs = callRPC(web3Obj, RemoteMethod.eth_getLogs, jsonNode)
    #echo "outgoingLogs: ", outgoingLogs

    var logs: seq[JsonNode] = concat(incomingLogs.getElems, outgoingLogs.getElems)
    for obj in logs:
      let txHash = obj["transactionHash"].getStr
      let blockNumber = fromHex[int](obj["blockNumber"].getStr)
      let blockHash = obj["blockHash"].getStr
      let parsedLog = parseLog(obj)
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
  except IOError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except KeyError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except OSError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except Web3Error as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except Exception as e: # raised by parseJson
      raise (ref TxHistoryError)(parent: e, msg: errorMsg)


proc fetchTxDetails*(address: types.Address, txToData: var TransferMap)
  {.raises: [Defect, TxHistoryError].} =

  const errorMsg = "Error fetching transaction details"
  try:
    for tx in txToData.keys:
      let
        jsonNode =  try: parseJSON(fmt"""["{tx}"]""")
                    except Exception as e:
                      raise (ref TxHistoryError)(parent: e, msg: "Error " &
                        "parsing json with transaction key")
        txInfo = callRPC(web3Obj, RemoteMethod.eth_getTransactionByHash,
          jsonNode)
        txReceipt = callRPC(web3Obj, RemoteMethod.eth_getTransactionReceipt,
          jsonNode)

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
  except IOError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except OSError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except Web3Error as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)


proc fetchDbData*(address: types.Address): TxDbData {.raises:
  [Defect, TxHistoryDbError].} =

  const errorMsg = "Error fetching transaction data from the database"
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

    return dbData
  except SqliteError as e:
    raise (ref TxHistoryDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref TxHistoryDbError)(parent: e, msg: errorMsg)

proc saveTransferInfo*(transferInfo: TransferInfo) {.raises:
  [TxHistoryDbError].} =

  const errorMsg = "Error saving transfer info"
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
  except SqliteError as e:
    raise (ref TxHistoryDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref TxHistoryDbError)(parent: e, msg: errorMsg)

proc saveTransfer*(transfer: Transfer) {.raises: [TxHistoryDbError].} =

  const errorMsg = "Error saving transfer in the database"

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
  except SqliteError as e:
    raise (ref TxHistoryDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref TxHistoryDbError)(parent: e, msg: errorMsg)

proc writeToDb(dbData: TxDbData) {.raises: [TxHistoryDbError].} =

  const errorMsg = "Error writing transaction data to the database"
  try:
    echo "writeToDb"
    saveTransferInfo(dbData.info)
    for transfer in dbData.txToData.values:
      saveTransfer(transfer)
  except SqliteError as e:
    raise (ref TxHistoryDbError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref TxHistoryDbError)(parent: e, msg: errorMsg)

# Used for passing address strings to scheduler thread
# bool parameter stands for addedOrRemoved flag
var chan: Channel[tuple[address: string, addOrRemove: bool]]

# Locks when tx data are being fetched in schedulerProc
var fetchLock: RLock


let schedulerInterval = 2 * 60 * 1000

# Main history fetching proc
proc schedulerProc() {.thread, raises: [Defect, TxHistoryError].} =

  const errorMsg = "Error with transaction history scheduler"
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
          var dbData = fetchDbData(address)

          let dbBlockNumber = dbData.info.blockNumber
          let dbTxCount = dbData.info.txCount
          let dbBalance = dbData.info.balance

          # If this is an initial wallet scan, all of [dbBlockNumber, dbTxCount, dbBalance]
          # will be zero
          var lastBlockNumber = getLastBlockNumber()
          if lastBlockNumber > dbBlockNumber:
            # There are new blocks, check if outgoing tx count or balance changed
            let
              txCount = getValueForBlock(address, intToHex(lastBlockNumber),
                RemoteMethod.eth_getTransactionCount)
              balance = getValueForBlock(address, intToHex(lastBlockNumber),
                RemoteMethod.eth_getBalance)


            var txBlockRange: BlockRange
            if dbBlockNumber == 0:
              txBlockRange = txBinarySearch(address, lastBlockNumber)
            else:
              txBlockRange = [dbBlockNumber + 1, lastBlockNumber]
            var txToData = TransferMap()

            # Only fetch eth transfers if tx count or balance changed
            if dbTxCount != txCount or dbBalance != balance:
              fetchEthTxHashes(address, txBlockRange, txToData)

            # ERC-20 logs should be checked anyways
            fetchErc20Logs(address, txBlockRange, txToData)

            if len(txToData) > 0:
              fetchTxDetails(address, txToData)

            let transferInfo = TransferInfo(
              address: address,
              balance: balance,
              blockNumber: lastBlockNumber,
              txCount: txCount)
            writeToDb(TxDbData(info: transferInfo, txToData: txToData))

      sleep(schedulerInterval)
  except TxHistoryError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except TxHistoryDbError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except ValueError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except Exception as e: # raised by channel.recv()
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)

proc fetchTxHistory*(address: types.Address, toBlock: int): TransferMap
  {.raises: [Defect, TxHistoryError].} =

  const errorMsg = "Error fetching transaction history"
  try:
    var txToData = TransferMap()

    # Find block range that we will search for balance changes
    let txBlockRange: BlockRange = txBinarySearch(address, toBlock)
    if txBlockRange == [0, 0]:
      # No txs found
      return txToData

    fetchEthTxHashes(address, txBlockRange, txToData)
    fetchErc20Logs(address, txBlockRange, txToData)

    fetchTxDetails(address, txToData)
    for transfer in txToData.values:
      saveTransfer(transfer)

    return txToData
  except TxHistoryError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except TxHistoryDbError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)

proc getTransfersByAddress*(address: types.Address, toBlock: int): TransferMap
  {.raises: [Defect, TxHistoryError].} =

  const errorMsg = "Error getting transfers by address"

  try:
    var dbData = fetchDbData(address)
    if dbData.info.blockNumber == 0:
      # Nothing has been fetched yet, wait for
      # schedulerProc to fetch it
      withRLock(fetchLock):
        dbData = fetchDbData(address)
    elif dbData.info.blockNumber > toBlock:
      # Fetch a previous range
      let transferMap = fetchTxHistory(address, toBlock)
      dbData.txToData = transferMap

    return dbData.txToData
  except TxHistoryError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)
  except TxHistoryDbError as e:
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)

proc init*(addresses: seq[types.Address]) {.raises: [Defect, TxHistoryError].} =

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
  except Exception as e: # raised by channel.send()
    raise (ref TxHistoryError)(parent: e, msg: errorMsg)