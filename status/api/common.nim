{.push raises: [Defect].}

import # std libs
  std/[os, tables, typetraits]

import # vendor libs
  sqlcipher, web3, web3/ethtypes

from web3/conversions as web3_conversions import `$`

import # status modules
  ../private/common,
  ../private/[accounts/generator/generator, callrpc, database, settings,
              token_prices, util]

from ../private/conversions import parseAddress, readValue, writeValue
from ../private/extkeys/types import Mnemonic

export
  `$`, common, database, ethtypes, generator, Mnemonic, parseAddress, readValue,
  sqlcipher, util, writeValue

type
  StatusApiDefect* = object of StatusDefect

  StatusApiError* = object of StatusError

  StatusObject* = ref object
    accountsGenerator*: Generator
    accountsDbConn: DbConn
    dataDir*: string
    userDbConn: DbConn
    web3Conn: Table[string, Web3]
    priceMap*: PriceMap


proc new*(T: type StatusObject, dataDir: string,
  accountsDbFileName: string = "accounts.sql"): DbResult[T] =

  let
    accountsDb = ?initDb(dataDir / accountsDbFileName).mapErrTo(
      InitFailure)
    generator = Generator.new()

  ok T(accountsDbConn: accountsDb, dataDir: dataDir, accountsGenerator: generator,
    web3Conn: initTable[string, Web3](), priceMap: newTable[string, ToPriceMap]())

proc accountsDb*(self: StatusObject): DbConn {.raises: [].} =
  self.accountsDbConn

proc isLoggedIn*(self: StatusObject): bool {.raises: [].} =
  not distinctBase(self.userDbConn).isNil and self.userDbConn.isOpen

proc userDb*(self: StatusObject): DbResult[DbConn] {.raises: [].} =
  if distinctBase(self.userDbConn).isNil:
    return err NotInitialized
  ok self.userDbConn

proc closeUserDb*(self: StatusObject): DbResult[void] {.raises: [].} =
  try:
    (?self.userDb).close()
  except SqliteError, Exception:
    return err CloseFailure
  self.userDbConn = nil
  ok()

proc close*(self: StatusObject): DbResult[void] {.raises: [].} =
  if self.isLoggedIn:
    ?self.closeUserDb()
  try:
    self.accountsDb.close()
    ok()
  except SqliteError, Exception:
    err CloseFailure

proc initUserDb*(self: StatusObject, keyUid, password: string): DbResult[void] =
  self.userDbConn = ?initDb(self.dataDir / keyUid & ".db", password)
  ok()

proc web3*(self: StatusObject, network: string): Web3Result[Web3] =
  let
    userDb = ?self.userDb
      .mapErrTo(Web3Error(kind: web3Internal, internalError: UserDbNotLoggedIn))
    settings = ?userDb.getSettings
      .mapErrTo(Web3Error(kind: web3Internal, internalError: GetSettingsFailure))

  if not self.web3Conn.hasKey(network):
    let val = ?newWeb3(settings, network)
    self.web3Conn[network] = val

  let web3Conn = ?(catch self.web3Conn[network])
    .mapErrTo(Web3Error(kind: web3Internal, internalError: NotFound))

  ok web3Conn

proc web3*(self: StatusObject): Web3Result[Web3]  =
  let
    userDb = ?self.userDb
      .mapErrTo(Web3Error(kind: web3Internal, internalError: UserDbNotLoggedIn))
    settings = ?userDb.getSettings
      .mapErrTo(Web3Error(kind: web3Internal, internalError: GetSettingsFailure))

  if not self.web3Conn.hasKey(settings.currentNetwork):
    let val = ?newWeb3(settings, settings.currentNetwork)
    self.web3Conn[settings.currentNetwork] = val

  let web3Conn = ?(catch self.web3Conn[settings.currentNetwork])
    .mapErrTo(Web3Error(kind: web3Internal, internalError: NotFound))

  ok web3Conn
