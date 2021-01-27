import # nim libs
  os, json, options

import # vendor libs
  sqlcipher, json_serialization, web3/conversions as web3_conversions

import # nim-status libs
  ../../nim_status/lib/[pendingtxs, database, conversions],
  ../../nim_status/lib/migrations/sql_scripts_app

let passwd = "qwerty"
let path = currentSourcePath.parentDir() & "/build/myDatabase"
let db = initializeDB(path, passwd, newMigrationDefinition())

let tx = PendingTx(
  networkId: 1,
  transactionHash: "0x1234",
  blkNumber: 0,
  fromAddress: "0xabc",
  toAddress: "0xdef",
  txType: "default_type",
  data: "data_json"
)


# savePendingTx
db.savePendingTx(tx)

# getPendingOutboundTxsByAddress
var txs = db.getPendingOutboundTxsByAddress(1, "0xabc")
assert len(txs) == 1 and
       txs[0].transactionHash == "0x1234" and
       txs[0].fromAddress == "0xabc" and
       txs[0].toAddress == "0xdef" and
       txs[0].txType == "default_type" and
       txs[0].data == "data_json"

# deletePendingTx
db.deletePendingTx("0x1234")

txs = db.getPendingTxs(1)
assert len(txs) == 0


db.close()
removeFile(path)
