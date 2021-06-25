import # std libs
  std/[os, json]

import # vendor libs
  confutils, json_serialization, sqlcipher

import # nim-status libs
  ./account, ./accounts, ./chats, ./config, ./database,
  ./migrations/sql_scripts_accounts as acc_migration,
  ./migrations/sql_scripts_app as app_migration,
  ./multiaccount, ./settings

type StatusObject* = ref object
  config*: StatusConfig
  accountsDB*: DbConn
  userDB*: DbConn

proc new*(T: type StatusObject, dataDir, accountsDbFileName: string = "accounts.sql"): T =
  # Disabling migrations because we are reusing a status-go DB
  T(accountsDB: initializeDB(dataDir / accountsDbFileName,
    acc_migration.newMigrationDefinition(), true), dataDir: dataDir)

proc getAccounts*(self: StatusObject): seq[accounts.Account] =
  getAccounts(self.accountsDB)

proc saveAccount*(self: StatusObject, account: accounts.Account) =
  saveAccount(self.accountsDB, account)

proc updateAccountTimestamp*(self: StatusObject, timestamp: int64, keyUid: string) =
  updateAccountTimestamp(self.accountsDB, timestamp, keyUid)

proc createSettings*(self: StatusObject, settings: Settings, nodeConfig: JsonNode) =
  createSettings(self.userDB, settings, nodeConfig)

proc getSettings*(self: StatusObject): Settings =
  getSettings(self.userDB)

proc login*(self: StatusObject, keyUid: string, password: string) =
  self.userDB = initializeDB(self.config.rootDataDir / keyUid & ".db", password, app_migration.newMigrationDefinition(), true) # Disabling migrations because we are reusing a status-go DB
  echo "==============================="
  echo "DB path: " & (self.config.rootDataDir / keyUid & ".db")
  echo "Password: " & password
  let result = self.userDB.value("SELECT public_key from settings") # check if decryption worked
  echo "Result: "
  echo $result

proc multiAccountGenerateAndDeriveAddresses*(self: StatusObject,
  mnemonicPhraseLength: int, n: int, bip39Passphrase: string,
  paths: seq[string]): seq[MultiAccount] =

  return generateAndDeriveAddresses(mnemonicPhraseLength, n, bip39Passphrase, paths)

proc multiAccountStoreDerivedAccounts*(self: StatusObject,
  multiAcc: MultiAccount, password: string, dataDir: string,
  pathStrings: seq[string] = newSeq[string]()) =

  storeDerivedAccounts(multiAcc, password, dataDir, pathStrings)

proc loadAccount*(self: StatusObject, address: string, password: string, dir: string = ""): account.Account =
  return loadAccount(address, password, dir)

proc closeUserDB*(self: StatusObject) =
  self.userDB.close()

proc loadChats*(self: StatusObject): seq[Chat] =
  getChats(self.userDB)

proc close*(self: StatusObject) =
  self.userDB.close()
  self.accountsDB.close()

when isMainModule:
  let statusConfig = StatusConfig.load()
  let statusObj = init(statusConfig)
  # Start a REPL ...
