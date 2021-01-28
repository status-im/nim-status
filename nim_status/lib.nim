import lib/accounts
import lib/alias
import lib/alias/data
import lib/account
import lib/accounts
import lib/identicon
import lib/messages
import lib/chats
import lib/permissions
import lib/util

import lib/migration
import lib/database
import lib/migrations/sql_scripts_accounts as acc_migration
import lib/migrations/sql_scripts_app as app_migration
import sqlcipher

import nimcrypto
import strformat
import strutils
import unicode
import json
import os

export createAccount
export getAccounts;
export saveAccount;
export updateAccount;
export updateAccountTimestamp;
export deleteAccount;
export addPermissions, getPermissions, deletePermission

proc hashMessage*(message: string): string =
  ## hashMessage calculates the hash of a message to be safely signed by the keycard.
  ## The hash is calulcated as
  ##  keccak256("\x19Ethereum Signed Message:\n"${message length}${message}).
  ## This gives context to the signed message and prevents signing of transactions.
  var msg = message
  if isHexString(msg):
    try:
      msg = parseHexStr(msg[2..^1])
    except:
      discard
  const END_OF_MEDIUM = Rune(0x19).toUTF8
  const prefix = END_OF_MEDIUM & "Ethereum Signed Message:\n"
  "0x" & toLower($keccak_256.digest(prefix & $(msg.len) & msg))

proc generateAlias*(pubKey: string): string =
  ## generateAlias returns a 3-words generated name given a hex encoded (prefixed with 0x) public key.
  ## We ignore any error, empty string result is considered an error.
  result = ""
  if isPubKey(pubKey):
    try:
      let seed = truncPubKey(pubKey)
      const poly: uint64 = 0xB8
      let generator = Lsfr(poly: poly, data: seed)
      let adjective1 = adjectives[generator.next mod adjectives.len]
      let adjective2 = adjectives[generator.next mod adjectives.len]
      let animal = animals[generator.next mod animals.len.uint64]
      result = fmt("{adjective1} {adjective2} {animal}")
    except:
      discard

proc identicon*(str: string): string =
  ## identicon returns a base64 encoded icon given a string.
  ## We ignore any error, empty string result is considered an error.
  try:
    result = generateBase64(str)
  except:
    discard



##### TODO: move to somefile

type StatusObject* = ref object
  rootDataDir: string
  accountsDB*: DbConn
  userDB*: DbConn


proc init*(dataDir: string): StatusObject =
  result = new StatusObject
  result.rootDataDir = dataDir
  result.accountsDB = initializeDB(dataDir / "accounts.sql", acc_migration.newMigrationDefinition(), false) # Disabling migrations because we are reusing a status-go DB

proc openAccounts*(self: StatusObject): seq[Account] = 
  getAccounts(self.accountsDB)

proc openUserDB*(self: StatusObject, keyUid: string, password: string) =
  self.userDB = initializeDB(self.rootDataDir / keyUid & ".db", password, app_migration.newMigrationDefinition(), false) # Disabling migrations because we are reusing a status-go DB
  self.userDB.execScript("PRAGMA cipher_page_size = 1024");
  self.userDB.execScript("PRAGMA kdf_iter = 3200");
  self.userDB.execScript("PRAGMA cipher_hmac_algorithm = HMAC_SHA1");
  self.userDB.execScript("PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA1");
  echo "==============================="
  echo "DB path: " & (self.rootDataDir / keyUid & ".db") 
  echo "Password: " & password
  let result = self.userDB.value("SELECT public_key from settings") # check if decryption worked
  echo "Result: "
  echo result.get()

proc closeUserDB*(self: StatusObject) =
  self.userDB.close()

proc loadChats*(self: StatusObject): seq[Chat] =
  getChats(self.userDB)

proc close*(self: StatusObject) =
  self.userDB.close()
  self.accountsDB.close()