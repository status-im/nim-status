{.push raises: [Defect].}

import # std libs
  std/[os, typetraits]

import # vendor libs
  stew/results, sqlcipher

import # nim-status modules
  ../accounts/generator/generator, ../database

export database, generator, results, sqlcipher

type
  StatusError* = object of CatchableError

  StatusObject* = ref object
    accountsGenerator*: Generator
    accountsDbConn: DbConn
    dataDir*: string
    userDbConn: DbConn

  UserDbError* = object of StatusError

proc new*(T: type StatusObject, dataDir: string,
  accountsDbFileName: string = "accounts.sql"): T {.raises: [Exception,
  ref IOError, ref OSError, ref SqliteError].} =

  let
    accountsDb = initializeDB(dataDir / accountsDbFileName)
    generator = Generator.new()

  T(accountsDbConn: accountsDb, dataDir: dataDir, accountsGenerator: generator)

proc accountsDb*(self: StatusObject): DbConn =
  self.accountsDbConn

proc isLoggedIn*(self: StatusObject): bool =
  not distinctBase(self.userDbConn).isNil

proc userDb*(self: StatusObject): DbConn {.raises: [ref UserDbError].} =
  if distinctBase(self.userDbConn).isNil:
    raise newException(UserDbError,
      "User DB not initialized. Please login first.")
  self.userDbConn

proc closeUserDb*(self: StatusObject) {.raises: [Exception].} =
  self.userDb.close()
  self.userDbConn = nil

proc close*(self: StatusObject) {.raises: [Exception].} =
  if self.isLoggedIn:
    self.closeUserDb()
  self.accountsDb.close()

proc initUserDb*(self: StatusObject, keyUid, password: string) {.raises:
  [Exception].} =

  self.userDbConn = initializeDB(self.dataDir / keyUid & ".db", password)