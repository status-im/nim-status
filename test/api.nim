import # std libs
  std/[json, options, os, unittest]

import # vendor libs
  chronos, json_serialization, sqlcipher

import # status lib
  status/[api, private/settings]

import # test modules
  ./test_helpers

procSuite "api":
  asyncTest "api":

    let dataDir = currentSourcePath.parentDir() / "build" / "data"

    let statusObj = StatusObject.new(dataDir)
    check:
      statusObj.isLoggedIn == false
      statusObj.accountsGenerator != nil
      statusObj.dataDir == dataDir

    var account:PublicAccount = PublicAccount(
      name: "Test",
      loginTimestamp: 1.int64.some,
      identicon: "data:image/png;base64,something",
      keycardPairing: "",
      keyUid: "0x1234"
    )

    discard statusObj.saveAccount(account)
    statusObj.accountsDb.updateAccountTimestamp(1, "0x1234")
    let accountsResult = statusObj.getPublicAccounts()
    echo (%accountsResult.get).pretty
    check:
      accountsResult.isOk
      accountsResult.get[0].keyUid == "0x1234"
      accountsResult.get[0].loginTimestamp == 1.int64.some

    let
      password = "qwerty"
      settingsStr = """{
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
      settingsObj = Json.decode(settingsStr, Settings, allowUnknownFields = true)
      nodeConfig = %* {"config": 1}

    var logoutResult = statusObj.logout()
    check:
      # should not be able to log out when not logged in
      logoutResult.isErr
      statusObj.isLoggedIn == false

    # var getSettingResult =
    #   statusObj.getSetting(int, SettingsCol.LatestDerivedPath, 0)
    # check:
    #   # should not be able to get setting while logged out
    #   getSettingResult.isErr

    var getSettingsResult = statusObj.getSettings()
    check:
      # should not be able to get settings when logged out
      getSettingsResult.isErr

    let loginResult = statusObj.login(account.keyUid, password)
    check:
      loginResult.isOk
      loginResult.get == account

    statusObj.userDb.createSettings(settingsObj, nodeConfig)

    # getSettingResult =
    #   statusObj.getSetting[int](SettingsCol.LatestDerivedPath, 0)
    # check:
    #   # should not be able to get setting while logged out
    #   getSettingResult.isOk

    getSettingsResult = statusObj.getSettings()
    check:
      getSettingsResult.isOk
      getSettingsResult.get.keyUID == settingsObj.keyUID

    logoutResult = statusObj.logout()
    check:
      logoutResult.isOk
      statusObj.isLoggedIn == false


    statusObj.close()
    removeDir(datadir)
