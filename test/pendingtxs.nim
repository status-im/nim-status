import # std libs
  std/[json, options, os, unittest]

import # vendor libs
  chronos, json_serialization, sqlcipher

import # status lib
  status/private/[conversions, database, pendingtxs]

import # test modules
  ./test_helpers

procSuite "pendingtxs":
  asyncTest "pendingtxs":
    let password = "qwerty"
    let path = currentSourcePath.parentDir() & "/build/my.db"
    removeFile(path)
    let dbResult = initDb(path, password)
    check dbResult.isOk
    let db = dbResult.get

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
    check db.savePendingTx(tx).isOk

    # getPendingOutboundTxsByAddress
    var txsResult = db.getPendingOutboundTxsByAddress(1, "0xabc")
    check txsResult.isOk
    let txs = txsResult.get

    check:
      len(txs) == 1 and
        txs[0].transactionHash == "0x1234" and
        txs[0].fromAddress == "0xabc" and
        txs[0].toAddress == "0xdef" and
        txs[0].txType == "default_type" and
        txs[0].data == "data_json"

    # deletePendingTx
    check db.deletePendingTx("0x1234").isOk

    txsResult = db.getPendingTxs(1)

    check:
      txsResult.isOk
      len(txsResult.get) == 0

    db.close()
    removeFile(path)
