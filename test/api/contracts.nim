import # std libs
  std/[json, options, os, unittest]

import # vendor libs
  chronos, json_serialization, stint, sqlcipher, web3

import # status lib
  status/api/[accounts, auth, common, contracts, networks],
  status/private/settings

import # test modules
  ../test_helpers

procSuite "contracts api integration tests":
  asyncTest "snt contract - balanceOf":

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
    var getSntContractResult = statusObj.getSntContract
    check:
      getSntContractResult.isErr
      getSntContractResult.error == ContractError.MustBeLoggedIn

    # do login
    let loginResult = statusObj.login(account.keyUid, password)
    check: loginResult.isOk

    # check that getting networks works
    getSntContractResult = statusObj.getSntContract
    check:
      getSntContractResult.isOk
    let
      snt = getSntContractResult.get
      randomRealAddress = Address.fromHex("0x1062a747393198f70f71ec65a582423dba7e5ab3")
      balance = await snt.balanceOf(randomRealAddress).call()
    echo wei2Eth balance

    check statusObj.close.isOk
    removeDir(datadir)

  asyncTest "stickers contract - getPackData":

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
    var getStickersContractResult = statusObj.getStickersContract
    check:
      getStickersContractResult.isErr
      getStickersContractResult.error == ContractError.MustBeLoggedIn

    # do login
    let loginResult = statusObj.login(account.keyUid, password)
    check: loginResult.isOk

    # check that getting networks works
    getStickersContractResult = statusObj.getStickersContract
    check:
      getStickersContractResult.isOk


    let
      stickers = getStickersContractResult.get
      packCount = await stickers.packCount().call()

    check packCount > 0
    echo "# Sticker Packs: ", packCount.toString

    let res = await stickers.getPackData(0.u256).call()
    check:
      res.category.toHex == "0000000000000000000000000000000000000000000000000000000000000000"
      res.owner == Address.fromHex("0xEc0B681758f8Cccb4B8c2C908Bc40C615ed8F3DF")
      res.mintable == Bool.parse(true)
      res.timestamp == 1564031067.u256
      res.price == "20000000000000000000".u256
      res.contentHash.toHex == "e301017012207921223bbb9832c74da924dd43d9b92e03d92c0cf05922c0f9df4d6f6eabe53c0000000000000000000000000000000000000000000000000000"

    check statusObj.close.isOk
    removeDir(datadir)

  asyncTest "sticker market contract - getTokenData":

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
    var getSpContractResult = statusObj.getStickerMarketContract
    check:
      getSpContractResult.isErr
      getSpContractResult.error == ContractError.MustBeLoggedIn

    # do login
    let loginResult = statusObj.login(account.keyUid, password)
    check: loginResult.isOk

    # check that getting networks works
    getSpContractResult = statusObj.getStickerMarketContract
    check:
      getSpContractResult.isOk


    let
      sm = getSpContractResult.get
      tokenData = await sm.getTokenData(0.u256).call()

    check:
      tokenData.category.toHex == "0000000000000000000000000000000000000000000000000000000000000000"
      tokenData.timestamp == 1564031067.u256
      tokenData.contentHash.toHex == "e301017012207921223bbb9832c74da924dd43d9b92e03d92c0cf05922c0f9df4d6f6eabe53c0000000000000000000000000000000000000000000000000000"

    check statusObj.close.isOk
    removeDir(datadir)

  asyncTest "sticker pack contract - tokenPackId":

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
    var getSpContractResult = statusObj.getStickerPackContract
    check:
      getSpContractResult.isErr
      getSpContractResult.error == ContractError.MustBeLoggedIn

    # do login
    let loginResult = statusObj.login(account.keyUid, password)
    check: loginResult.isOk

    # check that getting networks works
    getSpContractResult = statusObj.getStickerPackContract
    check:
      getSpContractResult.isOk


    let
      sm = getSpContractResult.get
      packId = await sm.tokenPackId(120.u256).call()

    check:
      packId == 3.u256

    check statusObj.close.isOk
    removeDir(datadir)
