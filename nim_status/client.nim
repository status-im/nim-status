import # nim libs
  os

import # vendor libs
  sqlcipher

import # nim-status libs
  ./accounts,
  ./chats,
  ./database,
  ./migrations/sql_scripts_accounts as acc_migration,
  ./migrations/sql_scripts_app as app_migration

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
