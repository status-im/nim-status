import # std libs
  std/[json, options, os, unittest]

import # vendor libs
  chronos, json_serialization, sqlcipher

import # status lib
  status/api/[accounts, auth, common, networks],
  status/private/settings

import # test modules
  ../test_helpers

procSuite "networks api integration tests":
  asyncTest "get networks":

    let
      dataDir = currentSourcePath.parentDir().parentDir() / "build" / "data"
      password = "qwerty"

    let statusObjResult = StatusObject.new(dataDir)
    check statusObjResult.isOk
    let statusObj = statusObjResult.get

    let createAcctResult = statusObj.createAccount(12, "", password, dataDir)
    check: createAcctResult.isOk
    let account = createAcctResult.get

    # check that we can't get networks when not logged in
    var getNetworksResult = statusObj.getNetworks
    check:
      getNetworksResult.isErr
      getNetworksResult.error == NetworksError.MustBeLoggedIn

    # do login
    let loginResult = statusObj.login(account.keyUid, password)
    check: loginResult.isOk

    # check that getting networks works
    getNetworksResult = statusObj.getNetworks
    check:
      getNetworksResult.isOk
      getNetworksResult.get.len == DEFAULT_NETWORKS.len

    check statusObj.close.isOk
    removeDir(datadir)

  asyncTest "switch network":

    let
      dataDir = currentSourcePath.parentDir().parentDir() / "build" / "data"
      password = "qwerty"

    let statusObjResult = StatusObject.new(dataDir)
    check statusObjResult.isOk
    let statusObj = statusObjResult.get

    let createAcctResult = statusObj.createAccount(12, "", password, dataDir)
    check: createAcctResult.isOk
    let account = createAcctResult.get

    # check that we can't switch networks when not logged in
    var switchNetworkResult = statusObj.switchNetwork("not_logged_in")
    check:
      switchNetworkResult.isErr
      switchNetworkResult.error == NetworksError.MustBeLoggedIn

    # do login
    let loginResult = statusObj.login(account.keyUid, password)
    check: loginResult.isOk

    # get userDb instance
    let userDbResult = statusObj.userDb
    check: userDbResult.isOk
    let userDb = userDbResult.get

    # check default current network is correct
    var currentNetwork = userDb.getSetting(string, SettingsCol.CurrentNetwork)
    check:
      currentNetwork.isOk
      currentNetwork.get.isSome
      currentNetwork.get.get == DEFAULT_NETWORK_NAME

    # check that we can't switch to an unknown network
    switchNetworkResult = statusObj.switchNetwork("doesnt_exist")
    check:
      switchNetworkResult.isErr
      switchNetworkResult.error == NetworkDoesntExist

    # check that the current network hasn't changed
    currentNetwork = userDb.getSetting(string, SettingsCol.CurrentNetwork)
    check:
      currentNetwork.isOk
      currentNetwork.get.isSome
      currentNetwork.get.get == DEFAULT_NETWORK_NAME

    # check that switching networks works
    let newNetworkId = "testnet_rpc"
    switchNetworkResult = statusObj.switchNetwork(newNetworkId)
    currentNetwork = userDb.getSetting(string, SettingsCol.CurrentNetwork)
    check:
      switchNetworkResult.isOk
      currentNetwork.isOk
      currentNetwork.get.isSome
      currentNetwork.get.get == newNetworkId

    check statusObj.close.isOk
    removeDir(datadir)
