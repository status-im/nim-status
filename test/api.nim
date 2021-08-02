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

    let statusObjResult = StatusObject.new(dataDir)
    check statusObjResult.isOk
    let statusObj = statusObjResult.get
    check:
      statusObj.loginState == LoginState.loggedout
      statusObj.accountsGenerator != nil
      statusObj.dataDir == dataDir

    var account:PublicAccount = PublicAccount(
      name: "Test",
      loginTimestamp: 1.int64.some,
      identicon: "data:image/png;base64,something",
      keycardPairing: "",
      keyUid: "0x1234"
    )
    check:
      statusObj.saveAccount(account).isOk
      statusObj.accountsDb.updateAccountTimestamp(1, "0x1234").isOk

    let accountsResult = statusObj.getPublicAccounts()
    check accountsResult.isOk
    let accounts = accountsResult.get
    echo (%accounts).pretty

    check:
      accounts[0].keyUid == "0x1234"
      accounts[0].loginTimestamp == 1.int64.some

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
      statusObj.loginState == LoginState.loggedout

    # var getSettingResult =
    #   statusObj.getSetting(int, SettingsCol.LatestDerivedPath, 0)
    # check:
    #   # should not be able to get setting while logged out
    #   getSettingResult.isErr

    var getSettingsResult = statusObj.getSettings()
    check:
      # should not be able to get settings when logged out
      getSettingsResult.isErr
      getSettingsResult.error == SettingsError.MustBeLoggedIn

    let loginResult = statusObj.login(account.keyUid, password)
    check:
      loginResult.isOk
      loginResult.get == account

    let userDbResult = statusObj.userDb
    check userDbResult.isOk
    let userDb = userDbResult.get

    check userDb.createSettings(settingsObj, nodeConfig).isOk

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
      statusObj.loginState == LoginState.loggedout


    check statusObj.close.isOk
    removeDir(datadir)
