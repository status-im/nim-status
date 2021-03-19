import # nim libs
  json, options, os, times, unittest

import # vendor libs
  chronos, confutils, json_serialization, sqlcipher, web3/conversions as web3_conversions

import # nim-status libs
  ../nim_status/[accounts, client, config, conversions, database, settings],
  ./test_helpers

procSuite "client":
  asyncTest "client":

    let config = StatusConfig.load()
    let statusObj = init(config)

    var account:Account = Account(
      name: "Test",
      loginTimestamp: 1,
      identicon: "data:image/png;base64,something",
      keycardPairing: "",
      keyUid: "0x1234"
    )

    saveAccount(statusObj.accountsDB, account)
    updateAccountTimestamp(statusObj.accountsDB, 1, "0x1234")
    let accounts = statusObj.openAccounts()
    check:
      $statusObj.config.rootDataDir == "status_datadir"
      accounts[0].keyUid == "0x1234"

    let password = "qwerty"
    echo "### before login"
    statusObj.login(account.keyUid, password)
    echo "### after login"
    let settingsStr = """{
      "address": "0x1122334455667788990011223344556677889900",
      "chaos-mode": true,
      "networks/current-network": "mainnet",
      "dapps-address": "0x1122334455667788990011223344556677889900",
      "eip1581-address": "0x1122334455667788990011223344556677889900",
      "installation-id": "ABC-DEF-GHI",
      "key-uid": "XYZ",
      "latest-derived-path": 0,
      "networks/networks": [{"id":"mainnet_rpc","etherscan-link":"https://etherscan.io/address/","name":"Mainnet with upstream RPC","config":{"NetworkId":1,"DataDir":"/ethereum/mainnet_rpc","UpstreamConfig":{"Enabled":true,"URL":"wss://mainnet.infura.io/ws/v3/7230123556ec4a8aac8d89ccd0dd74d7"}}}],
      "name": "test",
      "photo-path": "ABXYZC",
      "preview-privacy?": false,
      "public-key": "0x123",
      "signing-phrase": "ABC DEF GHI",
      "wallet-root-address": "0x1122334455667788990011223344556677889900"
    }"""
    let settingsObj = Json.decode(settingsStr, Settings, allowUnknownFields = true)

    let nodeConfig = %* {"config": 1}
    echo "### before createSettings"
    createSettings(statusObj.userDB, settingsObj, nodeConfig)
    echo "### after createSettings"
    let dbSettings = getSettings(statusObj.userDB)
    echo "### after getSettings"
    check:
      dbSettings.keyUID == settingsObj.keyUID


    statusObj.close()
