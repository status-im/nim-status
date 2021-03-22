import confutils/defs

type StatusConfig* = object
  rootDataDir* {.
    defaultValue: "data"
    desc: "Root data directory"
    abbr: "d" .}: InputDir
  accountsDbFileName* {.
    defaultValue: "accounts.db"
    name: "accountsDB",
    desc: "Name of accounts db file under rootDataDir" .}: InputFile
