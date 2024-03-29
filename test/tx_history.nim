import # std libs
  std/[os, json, options, tables, unittest]

import # vendor libs
  json_serialization, sqlcipher

import # status lib
  status/private/[callrpc, conversions, database, settings, tx_history/types]

from status/private/tx_history import nil


# Initialize db
let passwd = "qwerty"
let path = currentSourcePath.parentDir() & "/build/my.db"
let dbResult = initDb(path, passwd)
check dbResult.isOk
let db = dbResult.get

#f315575765b14720b32382a61a89341a # real infura project id
#40ec14d9d9384d52b7fbcfecdde4e2c0 # test infura project id
#7230123556ec4a8aac8d89ccd0dd74d7 # no archive access

# Initialize module
let settingsStr = """{
    "address": "0x1122334455667788990011223344556677889900",
    "networks/current-network": "mainnet_rpc",
    "dapps-address": "0x1122334455667788990011223344556677889900",
    "eip1581-address": "0x1122334455667788990011223344556677889900",
    "installation-id": "ABC-DEF-GHI",
    "key-uid": "XYZ",
    "latest-derived-path": 0,
    "networks/networks": [{"id":"mainnet_rpc","etherscan-link":"https://etherscan.io/address/","name":"Mainnet with upstream RPC","config":{"NetworkId":1,"DataDir":"/ethereum/mainnet_rpc","UpstreamConfig":{"Enabled":true,"URL":"wss://mainnet.infura.io/ws/v3/40ec14d9d9384d52b7fbcfecdde4e2c0"}}}],
    "photo-path": "ABXYZC",

    "preview-privacy?": false,
    "public-key": "0x123",
    "signing-phrase": "ABC DEF GHI"
  }"""

let settingsObj = JSON.decode(settingsStr, Settings, allowUnknownFields = true)
let web3Obj = newWeb3(settingsObj)

check web3Obj.isOk
tx_history.setWeb3Obj(web3Obj.get)
tx_history.setDbConn(db)
let address = "0x4977E0B5ab94ff8A3c7625099cF3070775B92698"

# let txCount = tx_history.getValueForBlock(address, "latest", RemoteMethod.eth_getTransactionCount)
# echo "getValueForBlock, eth_getTransactionCount: ", txCount


# let balance = tx_history.getValueForBlock(address, "latest", RemoteMethod.eth_getBalance)
# echo "getValueForBlock, eth_getBalance: ", balance


# let lastBlockNumber = tx_history.getLastBlockNumber()
# echo "getLastBlockNumber: ", lastBlockNumber

# let lowestBlockNumber = tx_history.findLowestBlockNumber(address, [0, lastBlockNumber], RemoteMethod.eth_getBalance, balance)
# echo "lowestBlockNumber with balance ", balance, " : ", lowestBlockNumber

# let blockRange = tx_history.txBinarySearch(address, lastBlockNumber)
# echo "blockRange: ", blockRange

# let blockSeq = tx_history.balanceBinarySearch(address, blockRange)
# echo "blockSeq: ", blockSeq

#let blockSeq = @[11092173, 11092125, 11092119, 11091997, 11091959, 11091931, 10471488, 10465082, 10464949, 10464833, 9979835, 9928232, 9928159, 9285203, 9285158, 9285065, 9271886, 9271873, 9176634, 9170416]
# let blockSeq = @[11092173]
# var transferMap = TransferMap()
# tx_history.filterTxsForAddress(address, blockSeq, transferMap)

# echo "filterTxsForAddress begin"
# for t in tables.values(transferMap):
#   echo "Transfer: ", t

# echo "filterTxsForAddress end"

# tx_history.fetchTxDetails(address, transferMap)
# echo "fetchTxDetails begin"
# for t in tables.values(transferMap):
#   echo "Transfer: ", t

# echo "fetchTxDetails end"

# let blockRange = [0, 11092173]

# tx_history.fetchErc20Logs(address, blockRange, transferMap)
# echo "fetchErc20Logs begin"
# for t in tables.values(transferMap):
#   echo "Transfer: ", t

# echo "fetchErc20Logs end"


# CRUD tests

var ti = TransferInfo()
ti.address = address
ti.balance = 15
ti.blockNumber = 20
ti.txCount = 9

check tx_history.saveTransferInfo(ti).isOk

var t = Transfer()
t.id = "id"
t.txType = TxType.eth
t.address = address
t.blockNumber = 10
t.blockHash = "blockHash"
t.timestamp = 1000
t.gasPrice = 15
t.gasLimit = 30
t.gasUsed = 5
t.nonce = 100
t.txStatus = 2
t.input = "input"
t.txHash = "txHash"
t.value = 200
t.fromAddr = "0x1000"
t.toAddr = "0x2000"

check tx_history.saveTransfer(t).isOk

let dbDataResult = tx_history.fetchDbData(address)
check dbDataResult.isOk
let dbData = dbDataResult.get
echo "dbData.info: ", dbData.info
echo "dbData begin: "
for t in dbData.txToData.values:
  echo "transfer data: ", t
echo "dbData end: "

########### callRpc examples
# var jsonNode = parseJSON("""[]""")
# var resp = callRpc(web3Obj, eth_blockNumber, jsonNode)
# echo "eth_blockNumber response", resp
# var latestBlockNumber = fromHex[int](resp.result.getStr)
# var blockNumber = intToHex(latestBlockNumber /% 2) # intToHex(blockNumber/%2)
# echo "blockNumber, ", blockNumber

# jsonNode = parseJson(fmt"""["0x111d500fe567696D0224A7292D47AF11e8A4bCB4", "{blockNumber}"]""")
# echo "jsonNode ", jsonNode
# resp = callRpc(web3Obj, eth_getTransactionCount, jsonNode)
# echo "eth_getTransactionCount Response ", resp

# jsonNode = parseJson(fmt"""["0x111d500fe567696D0224A7292D47AF11e8A4bCB4", "{blockNumber}"]""")
# echo "jsonNode ", jsonNode
# resp = callRpc(web3Obj, eth_getTransactionCount, jsonNode)
# echo "eth_getTransactionCount Response ", resp

# resp = callRpc(web3Obj, eth_getBalance, jsonNode)
# echo "eth_getBalance Response ", resp

# let fromBlock = intToHex(latestBlockNumber - 1)
# let toBlock = intToHex(latestBlockNumber)

# jsonNode = parseJson("""[{"address": "0xedae1aaa4f1ba708a30ecf8f5e64551aca403850", "fromBlock": "0x0", "toBlock": "latest"}]""")
# resp = callRpc(web3Obj, eth_getLogs, jsonNode)
# echo "eth_getLogs Response ", resp


db.close()
removeFile(path)
