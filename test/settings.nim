import # std libs
  std/[json, options, os, unittest]

import # vendor libs
  chronos, json_serialization, json_serialization/std/options as json_options,
  sqlcipher

import # status lib
  status/private/[common, conversions, database, settings]

import # test modules
  ./test_helpers

procSuite "settings":
  asyncTest "settings":
    let password = "qwerty"
    let path = currentSourcePath.parentDir() & "/build/my.db"
    removeFile(path)
    let dbResult = initUserDb(path, password)
    check dbResult.isOk
    let db = dbResult.get

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

    check createSettings(db, settingsObj, nodeConfig).isOk

    let dbSettings1Result = db.getSettings
    check dbSettings1Result.isOk
    let dbSettings1 = dbSettings1Result.get

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

    var nodeConfigResult = getNodeConfig(db)
    check:
      nodeConfigResult.isOk
      $nodeConfigResult.get == $nodeConfig

    let testBool = true
    let testString = "ABCDE"
    let testJSON = %* { "abc": 123 }
    let testInt:int = 1
    let testInt64:int64 = 1
    let testUint:uint = 1
    let testUpstreamConfig = UpstreamConfig(enabled: true, url: "https://test.network")
    let testNetworkConfig = NetworkConfig(
      dataDir: "/test",
      networkId: NetworkId.Mainnet,
      upstreamConfig: testUpstreamConfig
    )
    let etherscanLink = some("https://test.etherscan.link")
    let testNetworks: seq[Network] = @[
      Network(config: testNetworkConfig, etherscanLink: etherscanLink, id: "test1Id", name: "test1Name"),
      Network(config: testNetworkConfig, etherscanLink: etherscanLink, id: "test2Id", name: "test2Name"),
      Network(config: testNetworkConfig, etherscanLink: etherscanLink, id: "test3Id", name: "test3Name"),
    ]
    var testAddress = "0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef".parseAddress.get
    var setting: Settings

    check:
      saveSetting(db, SettingsCol.ChaosMode, testBool).isOk
      saveSetting(db, SettingsCol.Currency, testString).isOk
      saveSetting(db, SettingsCol.CustomBootNodes, testJSON).isOk
      saveSetting(db, SettingsCol.CustomBootNodesEnabled, testJSON).isOk
      saveSetting(db, SettingsCol.DappsAddress, testAddress).isOk
      saveSetting(db, SettingsCol.Eip1581Address, testAddress).isOk
      saveSetting(db, SettingsCol.Fleet, testString).isOk
      saveSetting(db, SettingsCol.HideHomeTooltip, testBool).isOk
      saveSetting(db, SettingsCol.KeycardInstanceUID, testString).isOk
      saveSetting(db, SettingsCol.KeycardPairedOn, testInt64).isOk
      saveSetting(db, SettingsCol.KeycardPairing, testString).isOk
      saveSetting(db, SettingsCol.LastUpdated, testInt64).isOk
      saveSetting(db, SettingsCol.LatestDerivedPath, testInt).isOk
      saveSetting(db, SettingsCol.LogLevel, testString).isOk
      saveSetting(db, SettingsCol.Mnemonic, testString).isOk
      saveSetting(db, SettingsCol.Name, testString).isOk
      saveSetting(db, SettingsCol.CurrentNetwork, testString).isOk
      saveSetting(db, SettingsCol.Networks, testNetworks).isOk
      saveSetting(db, SettingsCol.NodeConfig, testJSON).isOk
      saveSetting(db, SettingsCol.NotificationsEnabled, testBool).isOk
      saveSetting(db, SettingsCol.PhotoPath, testString).isOk
      saveSetting(db, SettingsCol.PinnedMailservers, testJSON).isOk
      saveSetting(db, SettingsCol.PreferredName, testString).isOk
      saveSetting(db, SettingsCol.PreviewPrivacy, testBool).isOk
      saveSetting(db, SettingsCol.PublicKey, testString).isOk
      saveSetting(db, SettingsCol.RememberSyncingChoice, testBool).isOk
      saveSetting(db, SettingsCol.RemotePushNotificationsEnabled, testBool).isOk
      saveSetting(db, SettingsCol.PushNotificationsServerEnabled, testBool).isOk
      saveSetting(db, SettingsCol.PushNotificationsFromContactsOnly, testBool).isOk
      saveSetting(db, SettingsCol.SendPushNotifications, testBool).isOk
      saveSetting(db, SettingsCol.StickersPacksInstalled, testJSON).isOk
      saveSetting(db, SettingsCol.StickersPacksPending, testJSON).isOk
      saveSetting(db, SettingsCol.StickersRecentStickers, testJSON).isOk
      saveSetting(db, SettingsCol.SyncingOnMobileNetwork, testBool).isOk
      saveSetting(db, SettingsCol.Usernames, testJSON).isOk
      saveSetting(db, SettingsCol.WalletSetupPassed, testBool).isOk
      saveSetting(db, SettingsCol.WalletVisibleTokens, testJSON).isOk
      saveSetting(db, SettingsCol.Appearance, testInt).isOk
      saveSetting(db, SettingsCol.WakuEnabled, testBool).isOk
      saveSetting(db, SettingsCol.WakuBloomFilterMode, testBool).isOk

    let dbSettings2Result {.used.} = db.getSettings()
    check dbSettings2Result.isOk
    let dbSettings2 = dbSettings2Result.get

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

    nodeConfigResult = getNodeConfig(db)
    check:
      nodeConfigResult.isOk
      nodeConfigResult.get == testJSON

    db.close()
    removeFile(path)
