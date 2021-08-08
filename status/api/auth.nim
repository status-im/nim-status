{.push raises: [Defect].}

import # std libs
  std/[strutils, typetraits]

import # status modules
  ../private/[accounts/public_accounts, conversions, settings],
  ./common

export
  common
# TODO: do we still need these exports?
#   conversions, public_accounts, settings

type
  LoginResult* = Result[PublicAccount, string]

  LogoutResult* = Result[void, string]

proc login*(self: StatusObject, keyUid, password: string): LoginResult =

  if self.isLoggedIn:
    return LoginResult.err "Already logged in"

  try:
    let account = self.accountsDb.getPublicAccount(keyUid)
    if account.isNone:
      return LoginResult.err "Could not find account with keyUid " & keyUid

    self.initUserDb(keyUid, password)
    LoginResult.ok account.get

  except StatusApiError as e:
    if e.msg.contains "file is not a database":
      return LoginResult.err "Invalid password"
    return LoginResult.err "Failed to login, error: " & e.msg
  except PublicAccountDbError as e:
    return LoginResult.err "Failed to get public account: " & e.msg

proc logout*(self: StatusObject): LogoutResult {.raises: [].} =
  try:
    self.closeUserDb()
    LogoutResult.ok
  except StatusApiError as e:
    return LogoutResult.err "Error logging out: " & e.msg

proc validatePassword*(self: StatusObject, password, dir: string): bool =

  try:
    let address = self.userDb.getSetting(string, SettingsCol.WalletRootAddress)
    if address.isNone:
      return false
    let loadAcctResult = self.accountsGenerator.loadAccount(
      address.get.parseAddress, password, dir)
    return loadAcctResult.isOk
  except SettingDbError:
    return false
  except StatusApiError:
    return false
  except ValueError:
    return false
