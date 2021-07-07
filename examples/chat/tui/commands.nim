import # std libs
  std/[sequtils, strformat, strutils, sugar]

import # chat libs
  ./common, ./macros, ./screen, ./tasks

export common, screen, strutils, tasks

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

proc help*(T: type Connect): HelpText =
  let command = "connect"
  HelpText(command: command, description: "Connects to the waku network.")

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

proc help*(T: type CreateAccount): HelpText =
  let command = "createaccount"
  HelpText(command: command, aliases: aliased[command], parameters: @[
    CommandParameter(name: "password", description: "Password for the new " &
      "account.")
    ], description: "Creates a new Status account.")

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

proc help*(T: type Disconnect): HelpText =
  let command = "disconnect"
  HelpText(command: command, description: "Disconnects from the waku network.")

proc new*(T: type Disconnect, args: varargs[string]): T =
  T()

proc split*(T: type Disconnect, argsRaw: string): seq[string] =
  @[]

proc command*(self: ChatTUI, command: Disconnect) {.async, gcsafe, nimcall.} =
  if self.client.online:
    asyncSpawn self.client.disconnect()
  else:
    self.wprintFormatError(epochTime().int64, "client is not online.")


# ListAccounts -----------------------------------------------------------------

proc help*(T: type ListAccounts): HelpText =
  let command = "listaccounts"
  HelpText(command: command, aliases: aliased[command], description: "Lists " &
    "all existing Status accounts.")

proc new*(T: type ListAccounts, args: varargs[string]): T =
  T()

proc split*(T: type ListAccounts, argsRaw: string): seq[string] =
  @[]

proc command*(self: ChatTUI, command: ListAccounts) {.async, gcsafe, nimcall.} =
  asyncSpawn self.client.listAccounts()

# Login ------------------------------------------------------------------------

proc help*(T: type Login): HelpText =
  let command = "login"
  HelpText(command: command, parameters: @[
    CommandParameter(name: "index", description: "Index of existing account, " &
      "which can be retrieved using the `/list` command."),
    CommandParameter(name: "password", description: "Account password.")
    ], description: "Logs in to the Status account.")

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

    self.showModal("Enter password:")
    # asyncSpawn self.client.login(account, password)
  except:
    self.wprintFormatError(epochTime().int64, "invalid login arguments.")

# Logout -----------------------------------------------------------------------

proc help*(T: type Logout): HelpText =
  let command = "logout"
  HelpText(command: command, description: "Logs out of the currently logged " &
    "in Status account.")

proc new*(T: type Logout, args: varargs[string]): T =
  T()

proc split*(T: type Logout, argsRaw: string): seq[string] =
  @[]

proc command*(self: ChatTUI, command: Logout) {.async, gcsafe, nimcall.} =
  asyncSpawn self.client.logout()

# Quit -------------------------------------------------------------------------

proc help*(T: type Quit): HelpText =
  let command = "quit"
  HelpText(command: command, description: "Quits the chat client.")

proc new*(T: type Quit, args: varargs[string]): T =
  T()

proc split*(T: type Quit, argsRaw: string): seq[string] =
  @[]

proc command*(self: ChatTUI, command: Quit) {.async, gcsafe, nimcall.} =
  await self.stop()

# SendMessage ------------------------------------------------------------------

proc help*(T: type SendMessage): HelpText =
  let command = ""
  HelpText(command: command, aliases: aliased[command], parameters: @[
    CommandParameter(name: "message", description: "Message to send on the " &
      "network. Max length ???")
    ], description: "Sends a message on the waku network. By default, no " &
    "command is needed. Text entered that is not preceded by a command will " &
    "be interpreted as a send command, ie typing `hello` will be interpreted " &
    "as `/send hello`.")

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

# Help -------------------------------------------------------------------------
# Note: although "Help" is not alphabetically last, we need to keep this below
# all other `help()` definitions so that they are available to the
# `buildCommandHelp()` macro. Alternatively, we could use forward declarations
# at the top of the file, but this introduces an additional update for a
# developer implementing a new command.

proc help*(T: type Help): HelpText =
  let command = "help"
  HelpText(command: command, aliases: aliased[command], description:
    "Show this help text.")

proc new*(T: type Help, args: varargs[string]): T =
  T(command: args[0])

proc split*(T: type Help, argsRaw: string): seq[string] =
  @[argsRaw.split(" ")[0]]

proc command*(self: ChatTUI, command: Help) {.async, gcsafe, nimcall.} =
  let
    command = command.command
    helpTexts = buildCommandHelp()
    timestamp = epochTime().int64
  
  # display on screen
  trace "TUI showing cli help", helpTexts=(%helpTexts)

  proc forDisplay(help: HelpText): (string, string) =
    let
      command = help.command
      hasAliases = help.aliases.len > 0
      aliasPrefix = if hasAliases: ", /" else: ""
      aliases = aliasPrefix & help.aliases.join(", /")
    (command, aliases)

  proc commandLength(help: HelpText): int =
    let (command, aliases) = help.forDisplay
    result = command.len + aliases.len

  proc longest(helps: seq[HelpText]): int =
    result = 0
    for help in helps:
      let length = help.commandLength
      if length > result:
        result = length

  proc longest(params: seq[CommandParameter]): int =
    result = 0
    for param in params:
      let length = param.name.len
      if length > result:
        result = length

  if self.outputReady:
    self.printResult("Available commands:", timestamp)
    self.printResult("===================", timestamp)
    self.printResult("", timestamp) # print blank line

    let
      spacing = 2
      totalSpace = helpTexts.longest + spacing

    for helpText in helpTexts:
      let
        (command, aliases) = helpText.forDisplay
        desc = helpText.description
        spaces = totalSpace - helpText.commandLength
        paramsJoined = helpText.parameters.map(p => p.name).join("> <")
        hasParams = helpText.parameters.len > 0
        paramsList = if hasParams: fmt" <{paramsJoined}>" else: ""
        finalText = fmt"{spacing.indent()}/{command}{aliases}{paramsList}"

      self.printResult(finalText.replace("/, ", ""), timestamp)
      self.printResult(fmt"{(spacing * 2).indent}{desc}", timestamp)
      
      let
        params = helpText.parameters
        totalParamSpace = params.longest + spacing

      if params.len > 0:
        self.printResult(fmt"{(spacing * 2).indent}Parameters:", timestamp)

      for param in params:
        let
          name = param.name
          paramSpaces = totalParamSpace - name.len
          desc = param.description
        self.printResult(
          fmt"{(spacing * 3).indent()}<{name}>{paramSpaces.indent}{desc}", timestamp)

      # print a blank line
      self.printResult("", timestamp)

  trace "Sending help texts to the client", help=(%helpTexts)

