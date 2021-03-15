import # nim libs
  json, options, os, unittest

import # vendor libs
  chronos, json_serialization, sqlcipher, web3/conversions

import # nim-status libs
  ../nim_status/[accounts, callrpc, database, settings],
  ./test_helpers

procSuite "login_and_logout":
  asyncTest "login_and_logout":
    let accountData = "someAccount"
    let password = "qwerty"
    test_removeDB(accountData)

    try:
      check:
        web3_conn == nil

      discard callRPC(web3_conn, "eth_gasPrice", %[])

      check:
        "Should fail if reaches this point" == ""
    except:
      check:
        getCurrentExceptionMsg() == "web3 connection is not available"


    login(accountData, password)

    # Using an ugly global var :(
    let rGasPrice = callRPC(web3_conn, "eth_gasPrice", %[])

    check:
      rGasPrice.error == false
      rGasPrice.result.getStr()[0..1] == "0x"

    logout()

    try:
      check:
        web3_conn == nil

      discard callRPC(web3_conn, "eth_gasPrice", %[])

      check:
        "Should fail if reaches this point" == ""
    except:
      check:
        getCurrentExceptionMsg() == "web3 connection is not available"

    # Removing DB to be able to run the test again
    test_removeDB(accountData)
