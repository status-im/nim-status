import # std libs
  std/[json, options, os, unittest]

import # vendor libs
  chronos, json_serialization, options, sqlcipher, web3/conversions

import # status lib
  status/private/[callrpc, common, database, settings]

import # test modules
  ./test_helpers

procSuite "callrpc":
  asyncTest "callrpc":
    let password = "qwerty"
    let path = currentSourcePath.parentDir() & "/build/my.db"
    removeFile(path)
    let dbResult = initDb(path, password)
    check dbResult.isOk

    let db = dbResult.get

    let settingsStr = """{
      "address": "0x1122334455667788990011223344556677889900",
      "networks/current-network": "mainnet_rpc",
      "dapps-address": "0x1122334455667788990011223344556677889900",
      "eip1581-address": "0x1122334455667788990011223344556677889900",
      "installation-id": "ABC-DEF-GHI",
      "key-uid": "XYZ",
      "latest-derived-path": 0,
      "networks/networks": [{"id":"mainnet_rpc","etherscan-link":"https://etherscan.io/address/","name":"Mainnet with upstream RPC","config":{"NetworkId":1,"DataDir":"/ethereum/mainnet_rpc","UpstreamConfig":{"Enabled":true,"URL":"wss://mainnet.infura.io/ws/v3/220a1abb4b6943a093c35d0ce4fb0732"}}}],
      "photo-path": "ABXYZC",
      "preview-privacy?": false,
      "public-key": "0x123",
      "signing-phrase": "ABC DEF GHI"
    }"""

    let
      settingsObj = JSON.decode(settingsStr, Settings, allowUnknownFields = true)
      web3ObjResult = newWeb3(settingsObj)
    check web3ObjResult.isOk
    let
      web3Obj = web3ObjResult.get
      rGasPrice = await callRpc(web3Obj, eth_gasPrice, %[])

    check:
      rGasPrice.isOk
      rGasPrice.get.getStr()[0..1] == "0x"

    let rEthSign = await callRpc(web3Obj, "eth_sign", %[])

    check:
      rEthSign.isErr
      rEthSign.error.kind == web3ErrorKind.web3Rpc
      rEthSign.error.rpcError.code == -32601
      rEthSign.error.rpcError.message == "the method eth_sign does not exist/is not available"

    let rSendTransaction = await callRpc(web3Obj, "eth_sendTransaction", %* [%*{"from": "0x0000000000000000000000000000000000000000", "to": "0x0000000000000000000000000000000000000000", "value": "123"}])

    check:
      rSendTransaction.isErr
      rEthSign.error.kind == web3ErrorKind.web3Rpc
      rSendTransaction.error.rpcError.code == -32601
      rSendTransaction.error.rpcError.message == "the method eth_sendTransaction does not exist/is not available"

    db.close()
    removeFile(path)
