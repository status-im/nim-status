import # status modules
  ../private/settings, ./common

export
  common, settings

type
  GetSettingsResult* = Result[Settings, string]

proc getSettings*(self: StatusObject): GetSettingsResult =
  if not self.isLoggedIn:
    return GetSettingsResult.err "Not logged in. Must be logged in to get " &
      "settings."
  try:
    return GetSettingsResult.ok self.userDb.getSettings()
  except CatchableError as e:
    return GetSettingsResult.err e.msg
