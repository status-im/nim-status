{.push raises: [Defect].}

import # std libs
  std/[json, tables]

import # vendor libs
  chronicles, chronos, web3/ethtypes

import # status modules
  ../private/[util, token_prices, tokens],
  ./common

export common except setLoginState, setNetworkState
export tokens

type
  CustomTokenError*     = enum
    AddFailure          = "ct: failed to add custom token due a database error"
    DeleteFailure       = "ct: failed to delete custom token due a database " &
                            "error"
    GetFailure          = "ct: failed to get custom tokens due a database error"
    MustBeLoggedIn      = "ct: operation not permitted, must be logged in"
    TokenNotInPriceMap  = "ct: token or currency symbol not found in price map"
    UpdatePricesError   = "ct: error updating prices"
    UserDbError         = "ct: user db error, must be logged in"

  CustomTokenResult*[T] = Result[T, CustomTokenError]

proc addCustomToken*(self: StatusObject, address: Address, name, symbol,
  color: string, decimals: uint): CustomTokenResult[Token] =

  if self.loginState != LoginState.loggedin:
    return err MustBeLoggedIn

  let token = Token(address: address, name: name, symbol: symbol, color: color,
    decimals: decimals)

  let userDb = ?self.userDb.mapErrTo(UserDbError)
  ?userDb.addCustomToken(token).mapErrTo(AddFailure)

  ok token

proc deleteCustomToken*(self: StatusObject, address: Address):
  CustomTokenResult[Address] =

  if self.loginState != LoginState.loggedin:
    return err MustBeLoggedIn

  let userDb = ?self.userDb.mapErrTo(UserDbError)
  ?userDb.deleteCustomToken(address).mapErrTo(DeleteFailure)

  ok address

proc getCustomTokens*(self: StatusObject): CustomTokenResult[seq[Token]] =
  if self.loginState != LoginState.loggedin:
    return err MustBeLoggedIn

  let
    userDb = ?self.userDb.mapErrTo(UserDbError)
    tokens = ?userDb.getCustomTokens().mapErrTo(GetFailure)

  ok tokens

proc getPrice*(self: StatusObject, tokenSymbol: string, fiatCurrency: string):
  CustomTokenResult[float] {.raises: [Defect, ref KeyError].} =

  if self.loginState != LoginState.loggedin:
    return err MustBeLoggedIn

  if not contains(self.priceMap, tokenSymbol) or
     not contains(self.priceMap[tokenSymbol], fiatCurrency):
    return err TokenNotInPriceMap
  else:
    return ok self.priceMap[tokenSymbol][fiatCurrency].price

proc updatePrices*(self: StatusObject): Future[CustomTokenResult[void]]
  {.async.} =

  if self.loginState != LoginState.loggedin:
    return err MustBeLoggedIn

  let tokensResult = self.getCustomTokens()
  if tokensResult.isErr: return err tokensResult.error
  let tokens = tokensResult.get
  var tokenSyms: seq[string] = @[]
  for t in tokens:
    tokenSyms.add(t.symbol)

  let res = await updatePrices(tokenSyms, FIAT_CURRENCIES, true)
  if res.isOk:
    self.priceMap = res.get
    trace "updated token price map", priceMap = $(%self.priceMap)
    return ok()
  else:
    return err UpdatePricesError
