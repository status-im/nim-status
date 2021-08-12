{.push raises: [Defect].}

import # std libs
  std/[tables, typetraits]

import # status modules
  ../private/[accounts/public_accounts, conversions, settings, util],
  ./common

export
  common
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
    MustBeLoggedOut         = "auth: operation not permitted, must be logged " &
                                "out"
    ParseAddressError       = "auth: failed to parse address"
    UnknownError            = "auth: unknown error"
    UserDbError             = "auth: user DB error, must be logged in"
    WalletRootAddressError  = "auth: failed to get wallet root address setting"


  AuthResult*[T] = Result[T, AuthError]

proc login*(self: StatusObject, keyUid, password: string):
  AuthResult[PublicAccount] =

  if self.isLoggedIn:
    return err MustBeLoggedOut

  let account = ?self.accountsDb.getPublicAccount(keyUid).mapErrTo(
    GetAccountError)

  if account.isNone:
    return err InvalidKeyUid

  ?self.initUserDb(keyUid, password).mapErrTo(
    [(DbError.KeyError, InvalidPassword)].toTable, InitUserDbError)

  ok account.get

proc logout*(self: StatusObject): AuthResult[void] {.raises: [].} =
  ?self.closeUserDb().mapErrTo(CloseDbError)
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
