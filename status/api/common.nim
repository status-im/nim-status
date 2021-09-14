{.push raises: [Defect].}

import # std libs
  std/[os, sets, strformat, strutils, tables, typetraits]

import # vendor libs
  sqlcipher, web3, web3/ethtypes

from web3/conversions as web3_conversions import `$`

import # status modules
  ../private/common,
  ../private/[accounts/generator/generator, callrpc, database, events, settings,
              token_prices, util, waku]

from ../private/conversions import parseAddress, readValue, writeValue
from ../private/extkeys/types import Mnemonic
from ../private/opensea import Asset, AssetContract, Collection

export # modules
  common, database, ethtypes, events, find, generator, settings, sqlcipher, util

export # symbols
  `$`, Asset, Mnemonic, parseAddress, readValue, writeValue

type
  LoginState* = enum loggedout, loggingin, loggedin, loggingout

  NetworkState* = enum offline, connecting, online, disconnecting

  StatusObject* = ref object
    accountsDbConn: DbConn
    accountsGenerator*: Generator
    dataDir*: string
    loginState: LoginState
    networkState: NetworkState
    priceMap*: PriceMap
    signalHandler*: StatusSignalHandler
    topics*: OrderedSet[common.ContentTopic]
    userDbConn: DbConn
    wakuFilter*: bool
    wakuFilterHandler*: ContentFilterHandler
    wakuFilternode*: string
    wakuHistoryHandler*: QueryHandlerFunc
    wakuLightpush*: bool
    wakuLightpushnode*: string
    wakuNode*: WakuNode
    wakuPubSubTopics*: seq[string]
    wakuRlnRelay*: bool
    wakuStore*: bool
    wakuStorenode*: string
    web3Conn: Table[string, Web3]

proc new*(T: type StatusObject, dataDir: string,
  accountsDbFileName = "accounts.db",
  signalHandler = defaultStatusSignalHandler):
  DbResult[T] =

  let
    accountsDb = ?initAccountsDb(dataDir / accountsDbFileName).mapErrTo(InitFailure)
    generator = Generator.new()

  ok T(accountsDbConn: accountsDb, accountsGenerator: generator,
       dataDir: dataDir, loginState: loggedout, networkState: offline,
       priceMap: newTable[string, ToPriceMap](), signalHandler: signalHandler,
       wakuPubSubTopics: @[waku.DefaultTopic], wakuStore: true,
       web3Conn: initTable[string, Web3]())

proc accountsDb*(self: StatusObject): DbConn {.raises: [].} =
  self.accountsDbConn

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

proc initUserDb*(self: StatusObject, keyUid, password: string): DbResult[void] =
  self.userDbConn = ?initUserDb(self.dataDir / keyUid & ".db", password)
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

proc loginState*(self: StatusObject): LoginState =
  self.loginState

proc setLoginState*(self: StatusObject, state: LoginState) {.raises: [].} =
  self.loginState = state

proc networkState*(self: StatusObject): NetworkState =
  self.networkState

proc setNetworkState*(self: StatusObject, state: NetworkState) {.raises: [].} =
  self.networkState = state

# this and logic around login/out and dis/connect needs to be reconsidered
proc close*(self: StatusObject): DbResult[void] {.raises: [].} =
  if self.loginState == LoginState.loggedin:
    ?self.closeUserDb()
    self.setLoginState(LoginState.loggedout)

  try:
    self.accountsDb.close()
    ok()
  except SqliteError, Exception:
    err CloseFailure
