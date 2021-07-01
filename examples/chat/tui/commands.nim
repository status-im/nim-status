import # std libs
  std/strutils

import # chat libs
  ./screen, ./tasks

export screen, strutils, tasks

logScope:
  topics = "chat tui"

# Command types are defined in ./common to avoid circular dependency

# `split` procs for command args should only be concerned about splitting the
# raw string appropriately and avoid validation logic beyond bare minimum to
# generate the correct number of members in the returned `seq[string]`

# `command` procs should be reponsible for validation and execution with
# respect to fields on the instantiated types derived from Command; authoring
# `split` and `command` and type definitions that derive from Command (as well
# their respective `new` procs) will involve consideration of special strings
# (e.g. empty string) that a `split` proc populates into its returned
# `seq[string]` indicating e.g. a special value or missing arg or some other
# problem or special case that `split` ran into, and the correpsonding
# `command` proc should implement the appropriate logic to deal with those
# values

# Connect ----------------------------------------------------------------------

proc new*(T: type Connect, args: varargs[string]): T {.raises: [].} =
  T()

proc split*(T: type Connect, argsRaw: string): seq[string] =
  @[]

proc command*(self: ChatTUI, command: Connect) {.async, gcsafe, nimcall.} =
  if self.client.loggedin:
    asyncSpawn self.client.connect(self.client.account.name)
  else:
    self.wprintFormatError(epochTime().int64,
      "client is not logged in, cannot connect.")

# CreateAccount ----------------------------------------------------------------

proc new*(T: type CreateAccount, args: varargs[string]): T =
  T(password: args[0])

proc split*(T: type CreateAccount, argsRaw: string): seq[string] =
  @[argsRaw]

proc command*(self: ChatTUI, command: CreateAccount) {.async, gcsafe,
  nimcall.} =

  if command.password == "":
    self.wprintFormatError(epochTime().int64,
      "password cannot be blank, please provide a password as the first argument.")
  else:
    asyncSpawn self.client.generateMultiAccount(command.password)

# Disconnect -------------------------------------------------------------------

proc new*(T: type Disconnect, args: varargs[string]): T =
  T()

proc split*(T: type Disconnect, argsRaw: string): seq[string] =
  @[]

proc command*(self: ChatTUI, command: Disconnect) {.async, gcsafe, nimcall.} =
  if self.client.online:
    asyncSpawn self.client.disconnect()
  else:
    self.wprintFormatError(epochTime().int64, "client is not online.")

# Help -------------------------------------------------------------------------

proc new*(T: type Help, args: varargs[string]): T =
  T(command: args[0])

proc split*(T: type Help, argsRaw: string): seq[string] =
  @[argsRaw.split(" ")[0]]

proc command*(self: ChatTUI, command: Help) {.async, gcsafe, nimcall.} =
  let command = command.command
  discard

# ImportMnemonic -----------------------------------------------------------------

proc new*(T: type ImportMnemonic, args: varargs[string]): T =
  T(mnemonic: args[0], passphrase: args[1], password: args[2])

proc split*(T: type ImportMnemonic, argsRaw: string): seq[string] =
  let args = argsRaw.split(" ")
  var
    mnemonic: string
    passphrase: string
    password: string

  if args.len == 0:
    mnemonic = ""
    passphrase = ""
    password = ""
  elif args.len < 13:
    mnemonic = args[0..^1].join(" ")
    passphrase = ""
    password = ""
  elif args.len < 14:
    mnemonic = args[0..11].join(" ")
    passphrase = ""
    password = args[12]
  else:
    mnemonic = args[0..11].join(" ")
    passphrase = args[12]
    password = args[13..^1].join(" ")

  @[mnemonic, passphrase, password]

proc command*(self: ChatTUI, command: ImportMnemonic) {.async, gcsafe, nimcall.} =
  if command.mnemonic == "":
    self.wprintFormatError(epochTime().int64,
      "mnemonic cannot be blank, please provide a mnemonic as the first argument.")
  elif command.mnemonic.split(" ").len != 12:
    self.wprintFormatError(epochTime().int64,
      "mnemonic phrase must consist of 12 words separated by single spaces.")
  elif command.password == "":
    self.wprintFormatError(epochTime().int64,
      "password cannot be blank, please provide a password as the last argument.")
  else:
    asyncSpawn self.client.importMnemonic(command.mnemonic, command.passphrase,
      command.password)

# ListAccounts -----------------------------------------------------------------

proc new*(T: type ListAccounts, args: varargs[string]): T =
  T()

proc split*(T: type ListAccounts, argsRaw: string): seq[string] =
  @[]

proc command*(self: ChatTUI, command: ListAccounts) {.async, gcsafe, nimcall.} =
  asyncSpawn self.client.listAccounts()

# Login ------------------------------------------------------------------------

proc new*(T: type Login, args: varargs[string]): T {.raises: [].} =
  T(account: args[0], password: args[1])

proc split*(T: type Login, argsRaw: string): seq[string] =
  let firstSpace = argsRaw.find(" ")

  var
    account: string
    password: string

  if firstSpace != -1:
    account = argsRaw[0..(firstSpace - 1)]
    if argsRaw.len > firstSpace + 1:
      password = argsRaw[(firstSpace + 1)..^1]
    else:
      password = ""
  else:
    account = ""
    password = ""

  @[account, password]

proc command*(self: ChatTUI, command: Login) {.async, gcsafe, nimcall.} =
  try:
    let
      account = parseInt(command.account)
      password = command.password

    asyncSpawn self.client.login(account, password)
  except:
    self.wprintFormatError(epochTime().int64, "invalid login arguments.")

# Logout -----------------------------------------------------------------------

proc new*(T: type Logout, args: varargs[string]): T =
  T()

proc split*(T: type Logout, argsRaw: string): seq[string] =
  @[]

proc command*(self: ChatTUI, command: Logout) {.async, gcsafe, nimcall.} =
  asyncSpawn self.client.logout()

# Quit -------------------------------------------------------------------------

proc new*(T: type Quit, args: varargs[string]): T =
  T()

proc split*(T: type Quit, argsRaw: string): seq[string] =
  @[]

proc command*(self: ChatTUI, command: Quit) {.async, gcsafe, nimcall.} =
  await self.stop()

# SendMessage ------------------------------------------------------------------

proc new*(T: type SendMessage, args: varargs[string]): T =
  T(message: args[0])

proc split*(T: type SendMessage, argsRaw: string): seq[string] =
  @[argsRaw]

proc command*(self: ChatTUI, command: SendMessage) {.async, gcsafe, nimcall.} =
  if not self.client.online:
    self.wprintFormatError(epochTime().int64,
      "client is not online, cannot send message.")
  else:
    asyncSpawn self.client.sendMessage(command.message)
