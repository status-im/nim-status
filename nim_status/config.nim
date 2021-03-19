import confutils/defs


type StatusConfig* = object
  rootDataDir* {.
    defaultValue: "build"
    desc: "Root data directory"
    abbr: "d" .}: InputDir
  accountsDbFileName* {.
    defaultValue: "accounts.db"
    name: "accountsDB",
    desc: "Name of accounts db file under rootDataDir" .}: InputFile




