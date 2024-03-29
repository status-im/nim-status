{.push raises: [Defect].}

import # status modules
  ../private/[settings, util],
  ./common

export common except setLoginState, setNetworkState

type
  SettingsError* = enum
    GetSettingsError  = "settings: error getting settings from the database"
    MustBeLoggedIn    = "settings: operation not permitted, must be logged in"
    UserDbError       = "settings: user DB error, must be logged in"

  SettingsResult*[T] = Result[T, SettingsError]

proc getSettings*(self: StatusObject): SettingsResult[Settings] =
  if self.loginState != LoginState.loggedin:
    return err MustBeLoggedIn

  let
    userDb = ?self.userDb.mapErrTo(UserDbError)
    settings = ?userDb.getSettings.mapErrTo(GetSettingsError)

  ok settings
