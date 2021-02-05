import sqlcipher
import os, json, json_serialization
import options
import ../../nim_status/settings
import ../../nim_status/database
import ../../nim_status/callrpc
import ../../nim_status/accounts
import web3/conversions


let accountData = "someAccount"
let passwd = "qwerty"

test_removeDB(accountData)

try:
  assert web3_conn == nil
  discard callRPC(web3_conn, "eth_gasPrice", %[])
  assert "Should fail if reaches this point" == ""
except:
  assert getCurrentExceptionMsg() == "web3 connection is not available"


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
  assert getCurrentExceptionMsg() == "web3 connection is not available"

# Removing DB to be able to run the test again
test_removeDB(accountData)
