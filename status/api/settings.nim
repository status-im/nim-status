{.push raises: [Defect].}

import # status modules
  ../private/settings,
  ./common

export
  common

type
  GetSettingsResult* = Result[Settings, string]

proc getSettings*(self: StatusObject): GetSettingsResult =
  if not self.isLoggedIn:
    return GetSettingsResult.err "Not logged in. Must be logged in to get " &
      "settings."

  const errorMsg = "Error getting settings: "
  try:
    return GetSettingsResult.ok self.userDb.getSettings()
  except SettingDbError as e:
    return GetSettingsResult.err errorMsg & e.msg
  except StatusApiError as e:
    return GetSettingsResult.err errorMsg & e.msg