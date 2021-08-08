{.push raises: [Defect].}

import # std libs
  std/[os, typetraits]

import # vendor libs
  sqlcipher, stew/results, web3/ethtypes

from web3/conversions as web3_conversions import `$`

import # status modules
  ../private/common, ../private/[accounts/generator/generator, database]

from ../private/conversions import parseAddress, readValue, writeValue
from ../private/extkeys/types import Mnemonic

export
  `$`, common, database, ethtypes, generator, Mnemonic, parseAddress, readValue,
  results, sqlcipher, writeValue

type
  StatusApiDefect* = object of StatusDefect

  StatusApiError* = object of StatusError

  StatusObject* = ref object
    accountsGenerator*: Generator
    accountsDbConn: DbConn
    dataDir*: string
    userDbConn: DbConn

proc new*(T: type StatusObject, dataDir: string,
  accountsDbFileName: string = "accounts.sql"): T =

  const errorMsg = "Failed to initialize database"

  var accountsDb: DbConn
  try:
    accountsDb = initializeDB(dataDir / accountsDbFileName)
  except StatusApiError as e:
    raise (ref StatusApiDefect)(parent: e, msg: errorMsg)
  except DbError as e:
    raise (ref StatusApiDefect)(parent: e, msg: errorMsg)

  let generator = Generator.new()

  T(accountsDbConn: accountsDb, dataDir: dataDir, accountsGenerator: generator)

proc accountsDb*(self: StatusObject): DbConn =
  self.accountsDbConn

proc isLoggedIn*(self: StatusObject): bool {.raises: [].} =
  not distinctBase(self.userDbConn).isNil and self.userDbConn.isOpen

proc userDb*(self: StatusObject): DbConn {.raises: [StatusApiError].} =
  if distinctBase(self.userDbConn).isNil:
    raise newException(StatusApiError,
      "User DB not initialized. Please login first.")
  self.userDbConn

proc closeUserDb*(self: StatusObject) {.raises: [StatusApiError].} =
  try:
    self.userDb.close()
  except SqliteError as e:
    raise (ref StatusApiError)(parent: e, msg: "Error closing user database")
  except Exception as e:
    raise (ref StatusApiError)(parent: e, msg: "Error closing user database")
  self.userDbConn = nil

proc close*(self: StatusObject) {.raises: [StatusApiError].} =
  if self.isLoggedIn:
    self.closeUserDb()
  try:
    self.accountsDb.close()
  except SqliteError as e:
    raise (ref StatusApiError)(parent: e, msg: "Error closing accounts database")
  except Exception as e:
    raise (ref StatusApiError)(parent: e, msg: "Error closing accounts database")

proc initUserDb*(self: StatusObject, keyUid, password: string) {.raises:
  [Defect, StatusApiDefect].} =

  try:
    self.userDbConn = initializeDB(self.dataDir / keyUid & ".db", password)
  except DbError as e:
    # convert to a defect as we are in an unrecoverable state
    raise (ref StatusApiDefect)(parent: e, msg: "Error initializing user database")