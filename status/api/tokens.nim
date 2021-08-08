{.push raises: [Defect].}

import # vendor libs
  web3/ethtypes

import # status modules
  ../private/tokens,
  ./common

export
  common, tokens

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

  const errorMsg = "Error adding a custom token: "
  try:
    self.userDb.addCustomToken(token)
  except StatusApiError as e:
    return AddCustomTokenResult.err errorMsg & e.msg
  except TokenDbError as e:
    return AddCustomTokenResult.err errorMsg & e.msg

  AddCustomTokenResult.ok(token)

proc deleteCustomToken*(self: StatusObject, address: Address):
  DeleteCustomTokenResult =

  if not self.isLoggedIn:
    return DeleteCustomTokenResult.err "Not logged in. You must be logged in " &
      "to delete a custom token."

  const errorMsg = "Error deleting a custom token: "
  try:
    self.userDb.deleteCustomToken(address)
  except StatusApiError as e:
    return DeleteCustomTokenResult.err errorMsg & e.msg
  except TokenDbError as e:
    return DeleteCustomTokenResult.err errorMsg & e.msg

  DeleteCustomTokenResult.ok address

proc getCustomTokens*(self: StatusObject): CustomTokensResult =
  if not self.isLoggedIn:
    return CustomTokensResult.err "Not logged in. Must be logged in to get " &
      "custom tokens."

  const errorMsg = "Error getting wallet accounts: "
  try:
    let tokens = self.userDb.getCustomTokens()
    return CustomTokensResult.ok tokens
  except StatusApiError as e:
    return CustomTokensResult.err errorMsg & e.msg
  except TokenDbError as e:
    return CustomTokensResult.err errorMsg & e.msg