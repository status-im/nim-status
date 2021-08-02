{.push raises: [Defect].}

import # std libs
  std/[tables, typetraits]

import # status modules
  ../private/[accounts/public_accounts, conversions, settings, util],
  ./common

export common except setLoginState, setNetworkState
# TODO: do we still need these exports?
#   conversions, public_accounts, settings

type
  AuthError* = enum
    CloseDbError            = "auth: error closing user db"
    GetAccountError         = "auth: could not get account with specified " &
                                "keyUid"
    InvalidKeyUid           = "auth: could not find account with specified " &
                                "keyUid"
    InitUserDbError         = "auth: error initialising user db"
    InvalidPassword         = "auth: invalid password"
    MustBeLoggedIn          = "auth: operation not permitted, must be logged " &
                                "in"
    MustBeLoggedOut         = "auth: operation not permitted, must be logged " &
                                "out"
    ParseAddressError       = "auth: failed to parse address"
    UnknownError            = "auth: unknown error"
    UserDbError             = "auth: user DB error, must be logged in"
    WalletRootAddressError  = "auth: failed to get wallet root address setting"


  AuthResult*[T] = Result[T, AuthError]

proc login*(self: StatusObject, keyUid, password: string):
  AuthResult[PublicAccount] =

  if self.loginState != LoginState.loggedout:
    return err MustBeLoggedOut

  self.setLoginState(LoginState.loggingin)

  let account = self.accountsDb.getPublicAccount(keyUid)
  if account.isErr:
     self.setLoginState(LoginState.loggedout)
     return err GetAccountError

  if account.get.isNone:
    self.setLoginState(LoginState.loggedout)
    return err InvalidKeyUid

  let init = self.initUserDb(keyUid, password).mapErrTo(
    {DbError.KeyError: InvalidPassword}.toTable, InitUserDbError)

  if init.isErr:
    self.setLoginState(LoginState.loggedout)
    return err init.error

  self.setLoginState(LoginState.loggedin)
  ok account.get.get

proc logout*(self: StatusObject): AuthResult[void] =
  if self.loginState != LoginState.loggedin:
    return err MustBeLoggedIn

  self.setLoginState(LoginState.loggingout)

  let close = self.closeUserDb().mapErrTo(CloseDbError)
  if close.isErr:
    self.setLoginState(LoginState.loggedin)
    return close

  self.setLoginState(LoginState.loggedout)
  ok()

proc validatePassword*(self: StatusObject, password, dir: string):
  AuthResult[bool] =

  let
    userDb = ?self.userDb.mapErrTo(UserDbError)
    address = ?userDb.getSetting(string,
    SettingsCol.WalletRootAddress).mapErrTo(WalletRootAddressError)

  if address.isNone:
    return ok false

  let
    addressParsed = ?address.get.parseAddress.mapErrTo(ParseAddressError)
    loadAcctResult = self.accountsGenerator.loadAccount(addressParsed, password,
      dir)

  return ok loadAcctResult.isOk
