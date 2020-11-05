import sqlcipher
import os, json, json_serialization
import options
import ../../nim_status/lib/tokens
import ../../nim_status/lib/database
import web3/conversions

let passwd = "qwerty"
let path = currentSourcePath.parentDir() & "/build/myDatabase"
let db = initializeDB(path, passwd)

let tokensStr = """{
    "address": "0x1122334455667788990011223344556677889900",
    "name": "Status",
    "symbol": "SNT",
    "decimals": 18,
    "color": "#eeeeee"
  }"""

let tokensObj = JSON.decode(tokensStr, Token, allowUnknownFields = true)

db.addCustomToken(tokensObj)

var token_list = db.getCustomTokens()
assert token_list.len == 1
let token = token_list[0]

assert $token.address == "0x1122334455667788990011223344556677889900"
assert token.name == "Status"
assert token.symbol == "SNT"
assert token.decimals == 18
assert token.color == "#eeeeee"

db.deleteCustomToken(token.address)

token_list = db.getCustomTokens()

assert token_list.len == 0
