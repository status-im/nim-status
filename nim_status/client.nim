import # nim libs
  os

import # vendor libs
  confutils,
  json_serialization,
  sqlcipher

import # nim-status libs
  ./accounts,
  ./chats,
  ./config,
  ./database,
  ./migrations/sql_scripts_accounts as acc_migration,
  ./migrations/sql_scripts_app as app_migration

type StatusObject* = ref object
  config*: StatusConfig
  accountsDB*: DbConn
  userDB*: DbConn

proc init*(config: StatusConfig): StatusObject =
  result = new StatusObject
  result.config = config
  result.accountsDB = initializeDB($config.rootDataDir / $config.accountsDbFileName, acc_migration.newMigrationDefinition(), true) # Disabling migrations because we are reusing a status-go DB

proc openAccounts*(self: StatusObject): seq[Account] =
  getAccounts(self.accountsDB)

proc login*(self: StatusObject, keyUid: string, password: string) =
  self.userDB = initializeDB($self.config.rootDataDir / keyUid & ".db", password, app_migration.newMigrationDefinition(), true) # Disabling migrations because we are reusing a status-go DB
  self.userDB.execScript("PRAGMA cipher_page_size = 1024");
  self.userDB.execScript("PRAGMA kdf_iter = 3200");
  self.userDB.execScript("PRAGMA cipher_hmac_algorithm = HMAC_SHA1");
  self.userDB.execScript("PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA1");
  echo "==============================="
  echo "DB path: " & ($self.config.rootDataDir / keyUid & ".db")
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

when isMainModule:
  let statusConfig = StatusConfig.load()
  let statusObj = init(statusConfig)
  # Start a REPL ...
