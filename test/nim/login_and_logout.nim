import sqlcipher
import os, json, json_serialization
import options
import ../../nim_status/lib/settings
import ../../nim_status/lib/database
import ../../nim_status/lib/callrpc
import ../../nim_status/lib/accounts
import web3/conversions


let accountData = "someAccount"
let passwd = "qwerty"


try:
  assert web3_conn == nil
  discard callRPC(web3_conn, "eth_gasPrice", %[])
  assert "Should fail if reaches this point" == ""
except:
  assert getCurrentExceptionMsg() == "Web3 connection is not available"


login(accountData, passwd)

# Using an ugly global var :(
let rGasPrice = callRPC(web3_conn, "eth_gasPrice", %[])
assert rGasPrice.error == false
assert rGasPrice.result.getStr()[0..1] == "0x"

logout()


try:
  assert web3_conn == nil
  discard callRPC(web3_conn, "eth_gasPrice", %[])
  assert "Should fail if reaches this point" == ""
except:
  assert getCurrentExceptionMsg() == "Web3 connection is not available"


# Removing DB to be able to run the test again
removeFile(currentSourcePath.parentDir().parentDir().parentDir() & "/build/" & accountData)
