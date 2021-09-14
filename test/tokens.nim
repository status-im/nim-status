import # std libs
  std/[json, options, os, unittest]

import # vendor libs
  chronos, json_serialization, sqlcipher, web3/conversions

import # status lib
  status/private/[common, database, tokens]

import # test modules
  ./test_helpers

procSuite "custom tokens":
  asyncTest "crud":
    let password = "qwerty"
    let path = currentSourcePath.parentDir() & "/build/my.db"
    removeFile(path)
    let dbResult = initUserDb(path, password)
    check dbResult.isOk
    let db = dbResult.get

    let tokensStr = """{
      "networkId": 3,
      "address": "0x1122334455667788990011223344556677889900",
      "name": "StatusTest",
      "symbol": "TEST",
      "decimals": 18,
      "color": "#eeeeee"
    }"""

    let tokensObj = JSON.decode(tokensStr, Token, allowUnknownFields = true)
    check tokensObj.networkId == NetworkId.Ropsten

    var token_list = db.getCustomTokens(NetworkId.Ropsten)
    check:
      token_list.isOk
      token_list.get.len > 0

    var tokenCount = token_list.get.len

    check db.addCustomToken(tokensObj).isOk

    token_list = db.getCustomTokens(NetworkId.Ropsten)

    check:
      token_list.isOk
      token_list.get.len == tokenCount + 1

    var tokenResult = db.getCustomToken("TEST", NetworkId.Ropsten)

    check:
      tokenResult.isOk

    let token = tokenResult.get

    check:
      token.isSome
      token.get.networkId == NetworkId.Ropsten
      $token.get.address == "0x1122334455667788990011223344556677889900"
      token.get.name == "StatusTest"
      token.get.symbol == "TEST"
      token.get.decimals == 18
      token.get.color == "#eeeeee"

    check db.deleteCustomToken(token.get.address, NetworkId.Ropsten).isOk

    token_list = db.getCustomTokens(NetworkId.Ropsten)

    check:
      token_list.isOk
      token_list.get.len == tokenCount

    db.close()
    removeFile(path)

  asyncTest "snt token":
    let password = "qwerty"
    let path = currentSourcePath.parentDir() & "/build/my.db"
    removeFile(path)
    let dbResult = initUserDb(path, password)
    check dbResult.isOk
    let db = dbResult.get

    var sntTokenResult = db.getSntToken(NetworkId.Ropsten)
    check:
      sntTokenResult.isOk
      sntTokenResult.get.isSome

    var sntToken = sntTokenResult.get.get
    check:
      sntToken.symbol == "STT"
      $sntToken.address == "0xc55cf4b03948d7ebc8b9e8bad92643703811d162"
      sntToken.name == "Status Test Token"
      sntToken.decimals == 18

    sntTokenResult = db.getSntToken(NetworkId.Mainnet)
    check:
      sntTokenResult.isOk
      sntTokenResult.get.isSome

    sntToken = sntTokenResult.get.get
    check:
      sntToken.symbol == "SNT"
      $sntToken.address == "0x744d70fdbe2ba4cf95131626614a1763df805b9e"
      sntToken.name == "Status Network Token"
      sntToken.decimals == 18

    sntTokenResult = db.getSntToken(NetworkId.XDai)
    check:
      sntTokenResult.isOk
      sntTokenResult.get.isSome

    sntToken = sntTokenResult.get.get
    check:
      sntToken.symbol == "SNT"
      $sntToken.address == "0x044f6ae3aef34fdb8fddc7c05f9cc17f19acd516"
      sntToken.name == "Status Network Token"
      sntToken.decimals == 18

    sntTokenResult = db.getSntToken(NetworkId.Poa)
    check:
      sntTokenResult.isOk
      sntTokenResult.get.isNone

    db.close()
    removeFile(path)
