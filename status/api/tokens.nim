{.push raises: [Defect].}

import # vendor libs
  web3/ethtypes

import # status modules
  ../private/[util, tokens],
  ./common

export
  common, tokens

type
  CustomTokenError* = enum
    AddFailure      = "ct: failed to add custom token due a database error"
    DeleteFailure   = "ct: failed to delete custom token due a database error"
    GetFailure      = "ct: failed to get custom tokens due a database error"
    MustBeLoggedIn  = "ct: operation not permitted, must be logged in"
    UserDbError     = "ct: user db error, must be logged in"

  CustomTokenResult*[T] = Result[T, CustomTokenError]

proc addCustomToken*(self: StatusObject, address: Address, name, symbol,
  color: string, decimals: uint): CustomTokenResult[Token] =

  if not self.isLoggedIn:
    return err MustBeLoggedIn

  let token = Token(address: address, name: name, symbol: symbol, color: color,
    decimals: decimals)

  let userDb = ?self.userDb.mapErrTo(UserDbError)
  ?userDb.addCustomToken(token).mapErrTo(AddFailure)

  ok token

proc deleteCustomToken*(self: StatusObject, address: Address):
  CustomTokenResult[Address] =

  if not self.isLoggedIn:
    return err MustBeLoggedIn

  let userDb = ?self.userDb.mapErrTo(UserDbError)
  ?userDb.deleteCustomToken(address).mapErrTo(DeleteFailure)

  ok address

proc getCustomTokens*(self: StatusObject): CustomTokenResult[seq[Token]] =
  if not self.isLoggedIn:
    return err MustBeLoggedIn

  let
    userDb = ?self.userDb.mapErrTo(UserDbError)
    tokens = ?userDb.getCustomTokens().mapErrTo(GetFailure)
  ok tokens
