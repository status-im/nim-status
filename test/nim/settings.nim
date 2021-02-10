import # nim libs
  json, options, os, unittest, strformat

import # vendor libs
  chronos, json_serialization, json_serialization/std/options as json_options,
  sqlcipher, web3/conversions as web3_conversions, web3/ethtypes

import # nim-status libs
  ../../nim_status/[conversions, database, settings, accounts],
  ../../nim_status/migrations/sql_scripts_app,
  ./test_helpers

import ../../nim_status/hybrid/shim as hybrid

procSuite "settings":
  test "settings":
    let password = "qwerty"
    let path = currentSourcePath.parentDir() & "/build/my.db"
    removeFile(path)
    let db = initializeDB(path, password, newMigrationDefinition())

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

    createSettings(db, settingsObj, nodeConfig)
    # Set the global used in hybrid/shim module
    accounts.db_conn = db


    var hybridRpcJson = """{"method": "settings_saveSetting", "params": ["address", "0x11223344556677889900112233445566778899ff"]}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)

    hybridRpcJson = """{"method": "settings_saveSetting", "params": ["chaos-mode?", false]}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)

    hybridRpcJson = """{"method": "settings_saveSetting", "params": ["currency", "eur"]}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)

    hybridRpcJson = """{"method": "settings_saveSetting", "params": ["dapps-address", "0x11223344556677889900112233445566778899ff"]}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)

    hybridRpcJson = """{"method": "settings_saveSetting", "params": ["eip1581-address", "0x11223344556677889900112233445566778899ff"]}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)

    hybridRpcJson = """{"method": "settings_saveSetting", "params": ["fleet", "test-fleet"]}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)

    hybridRpcJson = """{"method": "settings_saveSetting", "params": ["installation-id", "new-id"]}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)

    hybridRpcJson = """{"method": "settings_saveSetting", "params": ["key-uid", "test-key-uid"]}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)

    hybridRpcJson = """{"method": "settings_saveSetting", "params": ["latest-derived-path", 2]}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)

    hybridRpcJson = """{"method": "settings_saveSetting", "params": ["mnemonic", "test-mnemonic"]}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)

    hybridRpcJson = """{"method": "settings_saveSetting", "params": ["name", "test-name"]}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)

    hybridRpcJson = """{"method": "settings_saveSetting", "params": ["networks/current-network", "test-current-network"]}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)

    let testJsonArr = """[{"id":"ropsten_rpc","etherscan-link":"https://etherscan.io/address/","name":"Ropsten with upstream RPC","config":{"NetworkId":1,"DataDir":"/ethereum/ropsten_rpc","UpstreamConfig":{"Enabled":true,"URL":"wss://ropsten.infura.io/ws/v3/7230123556ec4a8aac8d89ccd0dd74d7"}}}]"""
    hybridRpcJson = fmt"""{{"method": "settings_saveSetting", "params": ["networks/networks", {testJsonArr}]}}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)

    let rpcJson = """{"test": 123}"""
    hybridRpcJson = fmt"""{{"method": "settings_saveSetting", "params": ["node-config", {rpcJson}]}}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)

    hybridRpcJson = """{"method": "settings_saveSetting", "params": ["photo-path", "test-photo-path"]}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)

    hybridRpcJson = fmt"""{{"method": "settings_saveSetting", "params": ["pinned-mailservers", {rpcJson}]}}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)

    hybridRpcJson = """{"method": "settings_saveSetting", "params": ["preferred-name", "test-preferred-name"]}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)

    hybridRpcJson = """{"method": "settings_saveSetting", "params": ["preview-privacy?", true]}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)

    hybridRpcJson = """{"method": "settings_saveSetting", "params": ["public-key", "test-public-key"]}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)

    hybridRpcJson = """{"method": "settings_saveSetting", "params": ["signing-phrase", "test-signing-phrase"]}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)

    hybridRpcJson = """{"method": "settings_saveSetting", "params": ["appearance", 1234]}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)

    hybridRpcJson = fmt"""{{"method": "settings_saveSetting", "params": ["usernames", {rpcJson}]}}"""
    discard hybrid.callPrivateRPC(hybridRpcJson)


    hybridRpcJson = """{"method": "settings_getSettings"}"""
    let rpcSettingsStr = hybrid.callPrivateRPC(hybridRpcJson)

    echo "rpcSettings: ", rpcSettingsStr
    let rpcSettingsJson = parseJson(rpcSettingsStr)
    echo "rpcSettings[node-config]: ", rpcSettingsJson["networks/networks"]
    echo "rpcSettings[node-config] type: ", type(rpcSettingsJson["networks/networks"])
    check:
      rpcSettingsJson["address"].getStr == "0x11223344556677889900112233445566778899ff"
      rpcSettingsJson["chaos-mode?"].getBool == false
      rpcSettingsJson["currency"].getStr == "eur"
      #rpcSettingsJson["custom-bootnodes"].getStr == rpcJson
      rpcSettingsJson["dapps-address"].getStr == "0x11223344556677889900112233445566778899ff"
      rpcSettingsJson["eip1581-address"].getStr == "0x11223344556677889900112233445566778899ff"
      rpcSettingsJson["fleet"].getStr == "test-fleet"
      rpcSettingsJson["installation-id"].getStr == "new-id"
      rpcSettingsJson["key-uid"].getStr == "test-key-uid"
      rpcSettingsJson["latest-derived-path"].getInt == 2
      rpcSettingsJson["mnemonic"].getStr == "test-mnemonic"
      rpcSettingsJson["name"].getStr == "test-name"
      rpcSettingsJson["networks/current-network"].getStr == "test-current-network"
      rpcSettingsJson["networks/networks"] == parseJson(testJsonArr)
      rpcSettingsJson["node-config"] == parseJson(rpcJson)
      rpcSettingsJson["photo-path"].getStr == "test-photo-path"
      rpcSettingsJson["pinned-mailservers"] == parseJson(rpcJson)
      rpcSettingsJson["preferred-name"].getStr == "test-preferred-name"
      rpcSettingsJson["preview-privacy?"].getBool == true
      rpcSettingsJson["public-key"].getStr == "test-public-key"
      rpcSettingsJson["signing-phrase"].getStr == "test-signing-phrase"
      rpcSettingsJson["appearance"].getInt == 1234
      rpcSettingsJson["usernames"] == parseJson(rpcJson)


    deleteSettings(db)
    createSettings(db, settingsObj, nodeConfig)

    let dbSettings1 = getSettings(db)

    check:
      settingsObj.userAddress == dbSettings1.userAddress
      settingsObj.chaosMode.isNone
      dbSettings1.chaosMode.get == false
      settingsObj.currentNetwork == dbSettings1.currentNetwork
      settingsObj.dappsAddress == dbSettings1.dappsAddress
      settingsObj.eip1581Address == dbSettings1.eip1581Address
      settingsObj.installationId == dbSettings1.installationId
      settingsObj.keyUID == dbSettings1.keyUID
      settingsObj.latestDerivedPath == dbSettings1.latestDerivedPath
      settingsObj.photoPath == dbSettings1.photoPath
      settingsObj.previewPrivacy == dbSettings1.previewPrivacy
      settingsObj.publicKey == dbSettings1.publicKey
      settingsObj.signingPhrase == dbSettings1.signingPhrase
      $getNodeConfig(db) == $nodeConfig

    let testBool = true
    let testString = "ABCDE"
    let testJSON = %* { "abc": 123 }
    let testInt:int = 1
    let testInt64:int64 = 1
    let testUint:uint = 1
    let testUpstreamConfig = UpstreamConfig(enabled: true, url: "https://test.network")
    let testNetworkConfig = NetworkConfig(
      dataDir: "/test",
      networkId: 1,
      upstreamConfig: testUpstreamConfig
    )
    let etherscanLink = some("https://test.etherscan.link")
    let testNetworks: seq[Network] = @[
      Network(config: testNetworkConfig, etherscanLink: etherscanLink, id: "test1Id", name: "test1Name"),
      Network(config: testNetworkConfig, etherscanLink: etherscanLink, id: "test2Id", name: "test2Name"),
      Network(config: testNetworkConfig, etherscanLink: etherscanLink, id: "test3Id", name: "test3Name"),
    ]
    var testAddress = "0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef".parseAddress
    var setting: Settings

    saveSetting(db, setting.chaosMode.columnName, testBool)
    saveSetting(db, setting.currency.columnName, testString)
    saveSetting(db, setting.customBootNodes.columnName, testJSON)
    saveSetting(db, setting.customBootNodesEnabled.columnName, testJSON)
    saveSetting(db, setting.dappsAddress.columnName, testAddress)
    saveSetting(db, setting.eip1581Address.columnName, testAddress)
    saveSetting(db, setting.fleet.columnName, testString)
    saveSetting(db, setting.hideHomeTooltip.columnName, testBool)
    saveSetting(db, setting.keycardInstanceUID.columnName, testString)
    saveSetting(db, setting.keycardPairedOn.columnName, testInt64)
    saveSetting(db, setting.keycardPairing.columnName, testString)
    saveSetting(db, setting.lastUpdated.columnName, testInt64)
    saveSetting(db, setting.latestDerivedPath.columnName, testInt)
    saveSetting(db, setting.logLevel.columnName, testString)
    saveSetting(db, setting.mnemonic.columnName, testString)
    saveSetting(db, setting.name.columnName, testString)
    saveSetting(db, setting.currentNetwork.columnName, testString)
    saveSetting(db, setting.networks.columnName, testNetworks)
    saveSetting(db, setting.nodeConfig.columnName, testJSON)
    saveSetting(db, setting.notificationsEnabled.columnName, testBool)
    saveSetting(db, setting.photoPath.columnName, testString)
    saveSetting(db, setting.pinnedMailservers.columnName, testJSON)
    saveSetting(db, setting.preferredName.columnName, testString)
    saveSetting(db, setting.previewPrivacy.columnName, testBool)
    saveSetting(db, setting.publicKey.columnName, testString)
    saveSetting(db, setting.rememberSyncingChoice.columnName, testBool)
    saveSetting(db, setting.remotePushNotificationsEnabled.columnName, testBool)
    saveSetting(db, setting.pushNotificationsServerEnabled.columnName, testBool)
    saveSetting(db, setting.pushNotificationsFromContactsOnly.columnName, testBool)
    saveSetting(db, setting.sendPushNotifications.columnName, testBool)
    saveSetting(db, setting.stickerPacksInstalled.columnName, testJSON)
    saveSetting(db, setting.stickersPacksPending.columnName, testJSON)
    saveSetting(db, setting.stickersRecentStickers.columnName, testJSON)
    saveSetting(db, setting.syncingOnMobileNetwork.columnName, testBool)
    saveSetting(db, setting.usernames.columnName, testJSON)
    saveSetting(db, setting.walletSetupPassed.columnName, testBool)
    saveSetting(db, setting.walletVisibleTokens.columnName, testJSON)
    saveSetting(db, setting.appearance.columnName, testInt)
    saveSetting(db, setting.wakuEnabled.columnName, testBool)
    saveSetting(db, setting.wakuBloomFilterMode.columnName, testBool)

    let dbSettings2 = getSettings(db)

    check:
      dbSettings2.chaosMode.get() == testBool
      dbSettings2.currency.get() == testString
      dbSettings2.customBootNodes.get() == testJson
      dbSettings2.customBootNodesEnabled.get() == testJson
      dbSettings2.dappsAddress == testAddress
      dbSettings2.eip1581Address == testAddress
      dbSettings2.fleet.get() == testString
      dbSettings2.hideHomeTooltip.get() == testBool
      dbSettings2.keycardInstanceUID.get() == testString
      dbSettings2.keycardPairedOn.get() == testInt64
      dbSettings2.keycardPairing.get() == testString
      dbSettings2.lastUpdated.get() == testInt64
      dbSettings2.latestDerivedPath == testUint
      dbSettings2.logLevel.get() == testString
      dbSettings2.mnemonic.get() == testString
      dbSettings2.name.get() == testString
      dbSettings2.currentNetwork == testString
      dbSettings2.networks == testNetworks
      dbSettings2.notificationsEnabled.get() == testBool
      dbSettings2.photoPath == testString
      dbSettings2.pinnedMailservers.get() == testJSON
      dbSettings2.preferredName.get() == testString
      dbSettings2.previewPrivacy == testBool
      dbSettings2.publicKey == testString
      dbSettings2.rememberSyncingChoice.get() == testBool
      dbSettings2.remotePushNotificationsEnabled.get() == testBool
      dbSettings2.pushNotificationsServerEnabled.get() == testBool
      dbSettings2.pushNotificationsFromContactsOnly.get() == testBool
      dbSettings2.sendPushNotifications.get() == testBool
      dbSettings2.stickerPacksInstalled.get() == testJSON
      dbSettings2.stickersPacksPending.get() == testJSON
      dbSettings2.stickersRecentStickers.get() == testJSON
      dbSettings2.syncingOnMobileNetwork.get() == testBool
      dbSettings2.userNames.get() == testJSON
      dbSettings2.walletSetupPassed.get() == testBool
      dbSettings2.walletVisibleTokens.get() == testJSON
      dbSettings2.appearance == testUint
      dbSettings2.wakuEnabled.get() == testBool
      dbSettings2.wakuBloomFilterMode.get() == testBool
      getNodeConfig(db) == testJSON

    db.close()
    removeFile(path)
