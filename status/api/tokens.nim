{.push raises: [Defect].}

import # vendor libs
  web3/ethtypes

import # status modules
  ../private/tokens, ./common

export common, ethtypes, tokens

type
  AddCustomTokenResult* = Result[Token, string]

  DeleteCustomTokenResult* = Result[Address, string]

  CustomTokensResult = Result[seq[Token], string]

proc addCustomToken*(self: StatusObject, address: Address, name, symbol,
  color: string, decimals: uint): AddCustomTokenResult =

  if not self.isLoggedIn:
    return AddCustomTokenResult.err "Not logged in. You must be logged in to " &
      "add a new custom token."

  let token = Token(address: address, name: name, symbol: symbol, color: color,
    decimals: decimals)

  try:
    self.userDb.addCustomToken(token)
  except CatchableError as e:
    return AddCustomTokenResult.err "Error adding a custom token: " & e.msg

  AddCustomTokenResult.ok(token)

proc deleteCustomToken*(self: StatusObject, address: Address):
  DeleteCustomTokenResult =

  if not self.isLoggedIn:
    return DeleteCustomTokenResult.err "Not logged in. You must be logged in " &
      "to delete a custom token."

  try:
    self.userDb.deleteCustomToken(address)
  except CatchableError as e:
    return DeleteCustomTokenResult.err "Error deleting a custom token: " & e.msg

  DeleteCustomTokenResult.ok address

proc getCustomTokens*(self: StatusObject): CustomTokensResult =
  if not self.isLoggedIn:
    return CustomTokensResult.err "Not logged in. Must be logged in to get " &
      "custom tokens."
  try:
    let tokens = self.userDb.getCustomTokens()
    return CustomTokensResult.ok tokens
  except CatchableError as e:
    return CustomTokensResult.err "Error getting wallet accounts: " & e.msg
