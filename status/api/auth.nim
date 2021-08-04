{.push raises: [Defect].}

import # std libs
  std/[strutils, typetraits]

import # status modules
  ../private/[accounts/public_accounts, conversions, settings],
  ./common

export
  common, conversions, public_accounts, settings

type
  LoginResult* = Result[PublicAccount, string]

  LogoutResult* = Result[void, string]


proc login*(self: StatusObject, keyUid, password: string): LoginResult {.raises:
  [Defect, SqliteError, ref ValueError].} =

  if self.isLoggedIn:
    return LoginResult.err "Already logged in"

  let account = self.accountsDb.getPublicAccount(keyUid)
  if account.isNone:
    return LoginResult.err "Could not find account with keyUid " & keyUid
  try:
    self.initUserDb(keyUid, password)
    LoginResult.ok account.get
  except Exception as e:
    if e.msg.contains "file is not a database":
      return LoginResult.err "Invalid password"
    return LoginResult.err "Failed to login, error: " & e.msg

proc logout*(self: StatusObject): LogoutResult =
  try:
    self.closeUserDb()
    LogoutResult.ok
  except Exception as e:
    return LogoutResult.err e.msg

proc validatePassword*(self: StatusObject, password, dir: string): bool
  {.raises: [Defect, ref AssertionError, Exception, ref IOError, ref OSError,
  SqliteError, UserDbError, ref ValueError].} =

  let address = self.userDb.getSetting(string, SettingsCol.WalletRootAddress)
  if address.isNone:
    return false
  let loadAcctResult = self.accountsGenerator.loadAccount(
    address.get.parseAddress, password, dir)
  return loadAcctResult.isOk
