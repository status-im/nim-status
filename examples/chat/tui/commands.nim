import # std libs
  std/[sequtils, strformat, strutils, sugar]

import # chat libs
  ./common, ./macros, ./screen, ./tasks

export common, screen, strutils, tasks

logScope:
  topics = "chat tui"

const hashCharSet = {'#'}

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

# AddCustomToken ----------------------------------------------------------------

proc help*(T: type AddCustomToken): HelpText =
  let command = "addcustomtoken"
  HelpText(command: command, aliases: aliased[command], parameters: @[
    CommandParameter(name: "address", description: "Address of the " &
      "custom token."),
    CommandParameter(name: "name", description: "Name of " &
      "the custom token."),
    CommandParameter(name: "symbol", description: "Symbol of the " &
      "custom token."),
    CommandParameter(name: "color", description: "(Optional) Color (in hex) for " &
      "custom token."),
    CommandParameter(name: "decimals", description: "(Optional) Number of decimals to use for " &
      "the custom token.")
    ], description: "Creates a new custom token ")

proc new*(T: type AddCustomToken, args: varargs[string]): T =
  var
    address = ""
    name = ""
    symbol = ""
    color = ""
    decimals = ""
  if args.len > 2:
    address = args[0]
    name = args[1]
    symbol = args[2]
  if args.len > 4:
    color = args[3]
    decimals = args[4]

  T(address: address, name: name, symbol: symbol, color: color, decimals: decimals)

proc split*(T: type AddCustomToken, argsRaw: string): seq[string] =
  argsRaw.split(" ")

proc command*(self: ChatTUI, command: AddCustomToken) {.async, gcsafe,
  nimcall.} =

  if command.address == "":
    self.wprintFormatError(epochTime().int64,
      "address cannot be empty, please provide an address.")
  elif command.name == "":
    self.wprintFormatError(epochTime().int64,
      "name cannot be empty, please provide a name.")
  elif command.symbol == "":
    self.wprintFormatError(epochTime().int64,
      "symbol cannot be empty, please provide a symbol.")
  else:
    asyncSpawn self.client.addCustomToken(command.address, command.name, command.symbol, command.color, command.decimals)


# AddWalletAccount ----------------------------------------------------------------

proc help*(T: type AddWalletAccount): HelpText =
  let command = "addwallet"
  HelpText(command: command, aliases: aliased[command], parameters: @[
    CommandParameter(name: "name", description: "(Optional) Display name for " &
      "the new account."),
    CommandParameter(name: "password", description: "Password of the current " &
      "account.")
    ], description: "Creates a new wallet account derived from the master " &
        "key of the currently logged in account")

proc new*(T: type AddWalletAccount, args: varargs[string]): T =
  var
    name = ""
    password = ""
  if args.len > 1:
    name = args[0]
    password = args[1]
  elif args.len > 0:
    password = args[0]

  T(name: name, password: password)

proc split*(T: type AddWalletAccount, argsRaw: string): seq[string] =
  argsRaw.split(" ")

proc command*(self: ChatTUI, command: AddWalletAccount) {.async, gcsafe,
  nimcall.} =

  try:
    if command.password == "":
      self.wprintFormatError(epochTime().int64,
        "password cannot be blank, please provide a password.")
    else:
      asyncSpawn self.client.addWalletAccount(command.name, command.password)
  except:
    self.wprintFormatError(epochTime().int64, "invalid arguments.")

# AddWalletPrivateKey ----------------------------------------------------------

proc help*(T: type AddWalletPrivateKey): HelpText =
  let command = "addwalletpk"
  HelpText(command: command, aliases: aliased[command], parameters: @[
    CommandParameter(name: "name", description: "(Optional) Display name for " &
      "the new account."),
    CommandParameter(name: "privatekey", description: "Private key of the " &
      "wallet account to import."),
    CommandParameter(name: "password", description: "Password of the current " &
      "account.")
    ], description: "Imports a wallet account from a private key.")

proc new*(T: type AddWalletPrivateKey, args: varargs[string]): T =
  var
    name = ""
    privateKey = ""
    password = ""
  if args.len > 2:
    name = args[0]
    privateKey = args[1]
    password = args[2]
  elif args.len > 1:
    privateKey = args[0]
    password = args[1]
  elif args.len > 0:
    privateKey = args[0]

  T(name: name, privateKey: privateKey, password: password)

proc split*(T: type AddWalletPrivateKey, argsRaw: string): seq[string] =
  argsRaw.split(" ")

proc command*(self: ChatTUI, command: AddWalletPrivateKey) {.async, gcsafe,
  nimcall.} =

  if command.privateKey == "" and command.password == "":
    self.wprintFormatError(getTime().toUnix(),
      "private key and password cannot be blank.")
  elif command.privateKey == "":
    self.wprintFormatError(getTime().toUnix(),
      "private key cannot be blank.")
  elif command.password == "":
    self.wprintFormatError(getTime().toUnix(),
      "password cannot be blank, please provide a password as the last argument.")
  else:
    asyncSpawn self.client.addWalletPrivateKey(command.name,
      command.privateKey, command.password)

# AddWalletSeed ------------------------------------------------------------

proc help*(T: type AddWalletSeed): HelpText =
  let command = "addwalletseed"
  HelpText(command: command, aliases: aliased[command], parameters: @[
    CommandParameter(name: "name", description: "(Optional) Display name for " &
      "the new account."),
    CommandParameter(name: "mnemonic", description: "The 12-word mnemonic " &
      "seed phrase of the wallet account to import."),
    CommandParameter(name: "password", description: "Password of the current " &
      "account.")
    ], description: "Imports a wallet account from a mnemonic seed.")

proc new*(T: type AddWalletSeed, args: varargs[string]): T =
  T(name: args[0], mnemonic: args[1], password: args[2], bip39Passphrase: args[3])

proc split*(T: type AddWalletSeed, argsRaw: string): seq[string] =
  let args = argsRaw.split(" ")
  var
    name: string
    mnemonic: string
    # bip39passphrase could be supplied (ie for use in Trezor hardwallets),
    # however here we are assuming it not being passed in for simplicity in
    # supplying input parameters to the command. This is in parity with how
    # status-desktop and status-react are doing it. status-desktop
    # implementation:
    # https://github.com/status-im/status-desktop/tree/master/src/status/libstatus/accounts.nim#L244
    passphrase = ""
    password: string

  if args.len == 0:
    name = ""
    mnemonic = ""
    password = ""
  elif args.len < 13:
    name = ""
    mnemonic = args[0..^1].join(" ")
    password = ""
  elif args.len < 14:
    name = ""
    mnemonic = args[0..11].join(" ")
    password = args[12..^1].join(" ")
  else:
    name = args[0]
    mnemonic = args[1..12].join(" ")
    password = args[13..^1].join(" ")

  @[name, mnemonic, password, passphrase]

proc command*(self: ChatTUI, command: AddWalletSeed) {.async, gcsafe,
  nimcall.} =

  if command.mnemonic == "" and command.password == "":
    self.wprintFormatError(getTime().toUnix(),
      "mnemonic and password cannot be blank.")
  elif command.mnemonic == "":
    self.wprintFormatError(getTime().toUnix(),
      "mnemonic cannot be blank.")
  elif command.password == "":
    self.wprintFormatError(getTime().toUnix(),
      "password cannot be blank, please provide a password as the last argument.")
  else:
    asyncSpawn self.client.addWalletSeed(command.name,
      command.mnemonic, command.password, command.bip39Passphrase)

# AddWalletWatchOnly ------------------------------------------------------------

proc help*(T: type AddWalletWatchOnly): HelpText =
  let command = "addwalletseed"
  HelpText(command: command, aliases: aliased[command], parameters: @[
    CommandParameter(name: "name", description: "(Optional) Display name for " &
      "the new account."),
    CommandParameter(name: "address", description: "The address of the " &
      "account to watch.")
    ], description: "Watches the transactions in a wallet account, without " &
      "the ability to interact with the wallet (ie sign transactions).")

proc new*(T: type AddWalletWatchOnly, args: varargs[string]): T =
  T(name: args[0], address: args[1])

proc split*(T: type AddWalletWatchOnly, argsRaw: string): seq[string] =
  var args = argsRaw.split(" ")
  args.keepIf(arg => arg != "")

  var
    name = ""
    address= ""

  if args.len == 1:
    name = ""
    address = args[0]
  elif args.len > 1:
    name = args[0]
    address = args[1]

  @[name, address]

proc command*(self: ChatTUI, command: AddWalletWatchOnly) {.async, gcsafe,
  nimcall.} =

  if command.address == "":
    self.wprintFormatError(getTime().toUnix(),
      "address cannot be blank.")
  else:
    asyncSpawn self.client.addWalletWatchOnly(command.address, command.name)

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
    self.wprintFormatError(getTime().toUnix(),
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
    self.wprintFormatError(getTime().toUnix(),
      "password cannot be blank, please provide a password as the first argument.")
  else:
    asyncSpawn self.client.createAccount(command.password)

# DeleteCustomToken ----------------------------------------------------------------

proc help*(T: type DeleteCustomToken): HelpText =
  let command = "deletecustomtoken"
  HelpText(command: command, aliases: aliased[command], parameters: @[
    CommandParameter(name: "address", description: "Address of the " &
      "custom token.")
    ], description: "Deletes custom token")

proc new*(T: type DeleteCustomToken, args: varargs[string]): T =
  var
    address = ""
  if args.len > 0:
    address = args[0]

  T(address: address)

proc split*(T: type DeleteCustomToken, argsRaw: string): seq[string] =
  @[argsRaw]

proc command*(self: ChatTUI, command: DeleteCustomToken) {.async, gcsafe,
  nimcall.} =

  if command.address == "":
    self.wprintFormatError(epochTime().int64,
      "address cannot be empty, please provide an address.")
  else:
    asyncSpawn self.client.deleteCustomToken(command.address)

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
    self.wprintFormatError(getTime().toUnix(), "client is not online.")

# GetCustomTokens -----------------------------------------------------------------

proc help*(T: type GetCustomTokens): HelpText =
  let command = "getcustomtokens"
  HelpText(command: command, aliases: aliased[command], description: "Lists " &
    "all existing custom tokens.")

proc new*(T: type GetCustomTokens, args: varargs[string]): T =
  T()

proc split*(T: type GetCustomTokens, argsRaw: string): seq[string] =
  @[]

proc command*(self: ChatTUI, command: GetCustomTokens) {.async, gcsafe, nimcall.} =
  asyncSpawn self.client.getCustomTokens()


# ImportMnemonic -----------------------------------------------------------------

proc help*(T: type ImportMnemonic): HelpText =
  let command = "importmnemonic"
  HelpText(command: command, aliases: aliased[command], parameters: @[
    CommandParameter(name: "mnemonic", description: "The 12-word mnemonic " &
      "seed phrase of the account to import."),
    CommandParameter(name: "bip39passphrase", description: "(Optional) The " &
      "BIP-39 passphrase used for securing against seed loss/theft."),
    CommandParameter(name: "password", description: "The password used to " &
      "encrypt the keystore file.")
    ], description: "Imports a Status account from a mnemoic.")

proc new*(T: type ImportMnemonic, args: varargs[string]): T =
  T(mnemonic: args[0], passphrase: args[1], password: args[2])

proc split*(T: type ImportMnemonic, argsRaw: string): seq[string] =
  let args = argsRaw.split(" ")
  var
    mnemonic: string
    # bip39passphrase could be supplied (ie for use in Trezor hardwallets),
    # however here we are assuming it not being passed in for simplicity in
    # supplying input parameters to the command. This is in parity with how
    # status-desktop and status-react are doing it. status-desktop
    # implementation:
    # https://github.com/status-im/status-desktop/tree/master/src/status/libstatus/accounts.nim#L244
    passphrase: string = ""
    password: string

  if args.len == 0:
    mnemonic = ""
    password = ""
  elif args.len < 13:
    mnemonic = args[0..^1].join(" ")
    password = ""
  else:
    mnemonic = args[0..11].join(" ")
    password = args[12..^1].join(" ")

  @[mnemonic, passphrase, password]

proc command*(self: ChatTUI, command: ImportMnemonic) {.async, gcsafe, nimcall.} =
  if command.mnemonic == "":
    self.wprintFormatError(getTime().toUnix(),
      "mnemonic cannot be blank, please provide a mnemonic as the first argument.")
  elif command.mnemonic.split(" ").len != 12:
    self.wprintFormatError(getTime().toUnix(),
      "mnemonic phrase must consist of 12 words separated by single spaces.")
  elif command.password == "":
    self.wprintFormatError(getTime().toUnix(),
      "password cannot be blank, please provide a password as the last argument.")
  else:
    asyncSpawn self.client.importMnemonic(command.mnemonic, command.passphrase,
      command.password)

# JoinTopic --------------------------------------------------------------------

proc help*(T: type JoinTopic): HelpText =
  let command = "jointopic"
  HelpText(command: command, aliases: aliased[command], parameters: @[
    CommandParameter(name: "topic", description: "Name of the topic to join.")
  ], description: "Watches for messages with the specified waku v2 content " &
    "topic.")

proc new*(T: type JoinTopic, args: varargs[string]): T =
  T(topic: args[0])

proc split*(T: type JoinTopic, argsRaw: string): seq[string] =
  @[argsRaw.strip()]

proc command*(self: ChatTUI, command: JoinTopic) {.async, gcsafe, nimcall.} =
  var topic = command.topic
  let topicSplit = topic.split('/')

  # if event.topic is a properly formatted waku v2 content topic then the
  # whole string will be passed to joinTopic
  if topicSplit.len != 5:
    # otherwise convert it to a properly formatted content topic
    topic = topic.strip(true, false, hashCharSet)
    if topic != "": topic = fmt"/toy-chat/2/{topic}/proto"

  if topic == "":
    self.wprintFormatError(getTime().toUnix(),
      "topic cannot be blank, please provide a topic as the first argument.")
  elif self.client.topics.contains(topic):
    self.printResult(fmt"Topic already joined: {topic}", getTime().toUnix())
  else:
    asyncSpawn self.client.joinTopic(topic)

# LeaveTopic -------------------------------------------------------------------

proc help*(T: type LeaveTopic): HelpText =
  let command = "leavetopic"
  HelpText(command: command, aliases: aliased[command], parameters: @[
    CommandParameter(name: "topic", description: "Name of the topic to leave.")
  ], description: "Stops watching for messages with the specified waku v2 " &
    "content topic.")

proc new*(T: type LeaveTopic, args: varargs[string]): T =
  T(topic: args[0])

proc split*(T: type LeaveTopic, argsRaw: string): seq[string] =
  @[argsRaw.strip()]

proc command*(self: ChatTUI, command: LeaveTopic) {.async, gcsafe, nimcall.} =
  let topic = command.topic

  if topic == "":
    self.wprintFormatError(getTime().toUnix(),
      "topic cannot be blank, please provide a topic as the first argument.")
  elif not self.client.topics.contains(topic):
    self.printResult(fmt"Topic not joined, no need to leave: {topic}",
      getTime().toUnix())
  else:
    asyncSpawn self.client.leaveTopic(topic)

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

# ListTopics -----------------------------------------------------------------

proc help*(T: type ListTopics): HelpText =
  let command = "listtopics"
  HelpText(command: command, aliases: aliased[command], description: "Lists " &
    "all topics that will be joined when client is online.")

proc new*(T: type ListTopics, args: varargs[string]): T =
  T()

proc split*(T: type ListTopics, argsRaw: string): seq[string] =
  @[]

proc command*(self: ChatTUI, command: ListTopics) {.async, gcsafe, nimcall.} =
  let
    timestamp = getTime().toUnix()
    topics = self.client.topics

  if topics.len > 0:
    var i = 1
    self.printResult("Joined topics:", timestamp)
    for topic in topics:
      self.printResult(fmt"{2.indent()}{i}. {topic}", timestamp)
      i = i + 1

  else:
    self.printResult("No topics joined. Join a topic using `/join <topic>`.",
      timestamp)

# ListWalletAccounts -----------------------------------------------------------------

proc help*(T: type ListWalletAccounts): HelpText =
  let command = "listwalletaccounts"
  HelpText(command: command, aliases: aliased[command], description: "Lists " &
    "all wallet accounts.")

proc new*(T: type ListWalletAccounts, args: varargs[string]): T =
  T()

proc split*(T: type ListWalletAccounts, argsRaw: string): seq[string] =
  @[]

proc command*(self: ChatTUI, command: ListWalletAccounts) {.async, gcsafe, nimcall.} =
  asyncSpawn self.client.listWalletAccounts()

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

    asyncSpawn self.client.login(account, password)
  except:
    self.wprintFormatError(getTime().toUnix(), "invalid login arguments.")

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
    self.wprintFormatError(getTime().toUnix(),
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
  HelpText(command: command, aliases: aliased[command], parameters: @[
    CommandParameter(name: "command", description: "(Optional) Command to " &
      "get help for. If omitted, help for all commands will be displayed.")
    ], description:
    "Show help text.")

proc new*(T: type Help, args: varargs[string]): T =
  T(command: args[0])

proc split*(T: type Help, argsRaw: string): seq[string] =
  let split = argsRaw.split(" ")
  result = @[]

  if split.len > 0:
    var command = split[0]
    # strip leading "/" if user typed it, ie /help /login => /help login
    if command.startsWith("/"): command = command.strip(chars = {'/'},
      leading = true, trailing = false)
    result.add command

proc command*(self: ChatTUI, command: Help) {.async, gcsafe, nimcall.} =
  let
    command = command.command
    timestamp = getTime().toUnix()

  trace "executing help", command

  var helpTexts = buildCommandHelp()

  if command != "":
    helpTexts = helpTexts.filter(help => help.command == command or help.aliases.contains(command))

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
    var introMsg = ""
    if command != "" and helpTexts.len == 0:
      introMsg = fmt"Command /{command} is invalid"
      self.wprintFormatError(timestamp, introMsg)
      return
    if command == "":
      introMsg = "Available commands:"
    else:
      introMsg = fmt"Help for /{command}:"
    self.printResult(introMsg, timestamp)
    self.printResult("=".repeat(introMsg.len), timestamp)
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
