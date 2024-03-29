{.push raises: [Defect].}

import # std libs
  std/sugar

import # nim-status modules
  ../private/[networks, settings, util],
  ./common

export Network

type
  NetworksError* = enum
    GetNetworksError          = "nets: error retrieving networks from settings"
    GetSettingsFailure        = "nets: failed to get web3 object, unable to " &
                                  "get settings"
    MustBeLoggedIn            = "nets: operation not permitted, must be " &
                                "logged in"
    NetworkDoesntExist        = "nets: network with specified ID doesn't exist"
    UpdateNetworkSettingError = "nets: error updating current network setting"
    UserDbError               = "nets: user db error, must be logged in"

  NetworksResult*[T] = Result[T, NetworksError]

proc getCurrentNetwork*(self: StatusObject): NetworksResult[Option[Network]] =

  if self.loginState != LoginState.loggedin:
    return err MustBeLoggedIn

  let
    userDb = ?self.userDb.mapErrTo(UserDbError)
    settings = ?userDb.getSettings.mapErrTo(GetSettingsFailure)
    networks = ?userDb.getSetting(seq[Network], SettingsCol.Networks, @[])
      .mapErrTo(GetNetworksError)
    currentNetwork = networks.find(
      (n: Network) => n.id == settings.currentNetwork)

  ok currentNetwork

proc getNetworks*(self: StatusObject): NetworksResult[seq[Network]] =

  if self.loginState != LoginState.loggedin:
    return err MustBeLoggedIn

  let
    userDb = ?self.userDb.mapErrTo(UserDbError)
    networks = ?userDb.getSetting(seq[Network], SettingsCol.Networks, @[])
      .mapErrTo(GetNetworksError)

  ok networks

proc switchNetwork*(self: StatusObject, networkId: string):
  NetworksResult[void] =

  if self.loginState != LoginState.loggedin:
    return err MustBeLoggedIn

  let
    userDb = ?self.userDb.mapErrTo(UserDbError)
    networks = ?userDb.getSetting(seq[Network], SettingsCol.Networks, @[])
      .mapErrTo(GetNetworksError)

  if not networks.contains((n: Network) => n.id == networkId):
    return err NetworkDoesntExist

  ?userDb.saveSetting(SettingsCol.CurrentNetwork, networkId).mapErrTo(
    UpdateNetworkSettingError)

  ok()
