import # nim libs
  json, options, os, unittest

import # vendor libs
  chronos, json_serialization, json_serialization/std/options as json_options,
  sqlcipher

import # status libs
  ../status/[conversions, database, settings],
  ../status/migrations/sql_scripts_app,
  ./test_helpers

procSuite "settings":
  asyncTest "settings":
    let password = "qwerty"
    let path = currentSourcePath.parentDir() & "/build/my.db"
    removeFile(path)
    let db = initializeDB(path, password)

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
