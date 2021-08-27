{.push raises: [Defect].}

import # std libs
  std/tables

import # vendor libs
  web3

import
  ../private/[contracts, tokens],
  ./common, ./networks

export contracts

type
  ContractError* = enum
    GetContractError      = "contracts: failed to get stickers contract"
    GetNetworkError       = "contracts: failed to get current network"
    GetSettingsFailure    = "contracts: failed to get web3 object, unable to " &
                              "get settings"
    GetSntTokenError      = "contracts: failed to get SNT token"
    GetTokenError         = "contracts: failed to get token"
    InvalidNetworkId      = "contracts: sticker contract address for network " &
                              "id doesn't exist"
    MustBeLoggedIn        = "contracts: operation not permitted, must be " &
                              "logged in"
    UserDbError           = "contracts: user db error, must be logged in"
    Web3Error             = "contracts: error getting web3 object"

  ContractResult*[T] = Result[T, ContractError]

proc getSntContract*(self: StatusObject): ContractResult[Sender[SntContract]] =

  if self.loginState != LoginState.loggedin:
    return err MustBeLoggedIn

  let
    userDb = ?self.userDb.mapErrTo(UserDbError)
    # settings = ?userDb.getSettings.mapErrTo(GetSettingsFailure)
    web3 = ?self.web3.mapErrTo(Web3Error)
    currNetwork = ?self.getCurrentNetwork().mapErrTo(GetNetworkError)

  if currNetwork.isNone: return err GetNetworkError

  let sntToken = ?userDb.getSntToken(currNetwork.get.config.networkId)
    .mapErrTo(GetSntTokenError)

  if sntToken.isNone: return err GetSntTokenError

  ok web3.contractSender(SntContract, sntToken.get.address)

proc getTokenContract*(self: StatusObject, symbol: string):
  ContractResult[Sender[Erc20Contract]] =

  if self.loginState != LoginState.loggedin:
    return err MustBeLoggedIn

  let
    userDb = ?self.userDb.mapErrTo(UserDbError)
    # settings = ?userDb.getSettings.mapErrTo(GetSettingsFailure)
    web3 = ?self.web3.mapErrTo(Web3Error)
    currNetwork = ?self.getCurrentNetwork().mapErrTo(GetNetworkError)

  if currNetwork.isNone: return err GetNetworkError

  let token = ?userDb.getCustomToken(symbol,
    currNetwork.get.config.networkId).mapErrTo(GetTokenError)

  if token.isNone: return err GetTokenError

  ok web3.contractSender(Erc20Contract, token.get.address)

proc getStickersContract*(self: StatusObject):
  ContractResult[Sender[StickersContract]] =

  if self.loginState != LoginState.loggedin:
    return err MustBeLoggedIn

  let
    web3 = ?self.web3.mapErrTo(Web3Error)
    currNetwork = ?self.getCurrentNetwork().mapErrTo(GetNetworkError)

  if currNetwork.isNone: return err GetNetworkError

  let address = ? catch(
    STICKERS_CONTRACT_ADDRESSES[currNetwork.get.config.networkId.int])
    .mapErrTo(InvalidNetworkId)

  ok web3.contractSender(StickersContract, address)

proc getStickerMarketContract*(self: StatusObject):
  ContractResult[Sender[StickerMarketContract]] =

  if self.loginState != LoginState.loggedin:
    return err MustBeLoggedIn

  let
    web3 = ?self.web3.mapErrTo(Web3Error)
    currNetwork = ?self.getCurrentNetwork().mapErrTo(GetNetworkError)

  if currNetwork.isNone: return err GetNetworkError

  let address = ? catch(
    STICKERMARKET_CONTRACT_ADDRESSES[currNetwork.get.config.networkId.int])
    .mapErrTo(InvalidNetworkId)

  ok web3.contractSender(StickerMarketContract, address)

proc getStickerPackContract*(self: StatusObject):
  ContractResult[Sender[StickerPackContract]] =

  if self.loginState != LoginState.loggedin:
    return err MustBeLoggedIn

  let
    web3 = ?self.web3.mapErrTo(Web3Error)
    currNetwork = ?self.getCurrentNetwork().mapErrTo(GetNetworkError)

  if currNetwork.isNone: return err GetNetworkError

  let address = ? catch(
    STICKERPACK_CONTRACT_ADDRESSES[currNetwork.get.config.networkId.int])
    .mapErrTo(InvalidNetworkId)

  ok web3.contractSender(StickerPackContract, address)
