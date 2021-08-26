import # std libs
  std/[strformat, strutils, tables]

import # vendor libs
  web3/conversions

import # status lib
  status/api/opensea

import # client modules
  ./parser

export parser

logScope:
  topics = "tui"

# `action` and `command` (see ./commands) procs are `{.async.}` for the
# convenience of e.g. interaction with channels and tasks. However, they should
# be self-contained with respect to their effects (with allowance for
# `await`-ing or `waitFor`-ing invocation of another `{.async.}` proc or
# blocking until return of a synchronous proc), i.e. other than invoking tasks
# (to do work on other threads) or sending to a channel (using `asyncSpawn`),
# they *should not* spawn independent asynchronous routines to cause side
# effects in the main thread that would happen *after* the current
# action/command has returned. They should also return as soon as possible and
# should be considered to effectively "block the main thread" while they are
# executing. The time budget for an action, from start to finish and including
# the execution time of procs it may call, is 16 milliseconds so as to maintain
# at least 60 FPS in the TUI.

const
  KEY_BACKSPACE = "KEY_BACKSPACE"
  KEY_DC = "KEY_DC"
  KEY_MOUSE = "KEY_MOUSE"
  KEY_RESIZE = "KEY_RESIZE"

proc dispatch*(self: Tui, command: string) {.gcsafe, nimcall.} =
  let (commandType, args, isCommand) = parse(command)

  if isCommand: commandCases()
  else:
    let
      cmd = command.split(' ')[0]
      timestamp = getTime().toUnix

    self.wprintFormatError(timestamp, fmt"Command {cmd} is invalid")
    error "TUI received malformed or unknown command", command

# InputKey ---------------------------------------------------------------------

proc action*(self: Tui, event: InputKey) {.async, gcsafe, nimcall.} =
  # if TUI is not ready for input then ignore it
  if self.inputReady:
    # handle mouse events and special keys e.g. arrow keys, ESCAPE, RETURN, etc.
    let
      key = event.key
      name = event.name

    case name:
      of ESCAPE:
        discard

      of KEY_BACKSPACE:
        self.deleteBackward()

      of KEY_DC:
        self.deleteForward()

      of KEY_MOUSE:
        var me: MEvent
        getmouse(addr me)
        discard

      of KEY_RESIZE:
        self.resizeScreen()

      of RETURN:
        let command = self.currentInput

        if command.strip(trailing = false) != "" and
           not aliased[DEFAULT_COMMAND].contains(command.strip()[1..^1]):
          self.currentInput.setLen(0)
          trace "TUI reset current input", currentInput=self.currentInput

          self.clearInput()
          self.dispatch(command)

      else:
        discard

# InputReady -------------------------------------------------------------------

proc action*(self: Tui, event: InputReady) {.async, gcsafe, nimcall.} =
  let
    ready = event.ready

  if ready:
    self.inputReady = true
    self.drawScreen()
    self.outputReady = true

# InputString ------------------------------------------------------------------

proc action*(self: Tui, event: InputString) {.async, gcsafe, nimcall.} =
  # if TUI is not ready for input then ignore it
  if self.inputReady:
    let input = event.str
    self.currentInput = self.currentInput & input
    trace "TUI updated current input", currentInput=self.currentInput

    self.printInput(input)

# AddWalletAccountEvent --------------------------------------------------------

proc action*(self: Tui, event: AddWalletAccountEvent) {.async, gcsafe,
  nimcall.} =

  # if TUI is not ready for output then ignore it
  if self.outputReady:
    if event.error != "":
      self.wprintFormatError(event.timestamp, event.error)
      return

    let
      timestamp = event.timestamp
      name = event.name
      address = $event.address
      abbrev = address[0..5] & "..." & address[^4..^1]

    self.printResult("Added wallet account:", timestamp)
    self.printResult(fmt"{2.indent()}{name} ({abbrev})", timestamp)

# CreateAccountEvent -----------------------------------------------------------

proc action*(self: Tui, event: CreateAccountEvent) {.async, gcsafe,
  nimcall.} =

  # if TUI is not ready for output then ignore it
  if self.outputReady:
    if event.error != "":
      self.wprintFormatError(event.timestamp, event.error)
      return

    let
      account = event.account
      timestamp = event.timestamp

      name = account.name
      keyUid = account.keyUid
      abbrev = keyUid[0..5] & "..." & keyUid[^4..^1]

    self.printResult("Created account:", timestamp)
    self.printResult(fmt"{2.indent()}{name} ({abbrev})", timestamp)

# DeleteWalletAccountEvent -----------------------------------------------------

proc action*(self: Tui, event: DeleteWalletAccountEvent) {.async, gcsafe,
  nimcall.} =

  # if TUI is not ready for output then ignore it
  if self.outputReady:
    if event.error != "":
      self.wprintFormatError(event.timestamp, event.error)
      return

    let
      address = event.address
      timestamp = event.timestamp

    self.printResult("Deleted wallet account:", timestamp)
    self.printResult(fmt"{2.indent()}{address}", timestamp)

# GetAssetsEvent ---------------------------------------------------------------

proc action*(self: Tui, event: GetAssetsEvent) {.async, gcsafe, nimcall.} =
  # if TUI is not ready for output then ignore it
  if self.outputReady:
    if event.error != "":
      self.wprintFormatError(event.timestamp, event.error)
      return

    let assets = event.assets
    let timestamp = event.timestamp
    trace "TUI showing assets", assets=(%assets)

    if assets.len > 0:
      self.printResult("Assets:", timestamp)
      var assetsIndexed: Table[string, seq[Asset]] = initTable[string, seq[Asset]]()
      for asset in assets:
        if not assetsIndexed.hasKey(asset.collection.name):
          assetsIndexed[asset.collection.name] = @[]

        assetsIndexed[asset.collection.name].add(asset)

      var i = 1
      for collectionName, items in assetsIndexed.pairs:
        self.printResult(fmt"{2.indent()}{i}. {collectionName}", timestamp)
        var j = 1
        for item in items:
          let
            name = item.name
            address = item.contract.address

          self.printResult(fmt"{4.indent()}{j}. {name} @ {address}", timestamp)
          j += 1

        i += 1
    else:
      self.printResult("No assets found.", timestamp)

# GetCustomTokensEvent ---------------------------------------------------------

proc action*(self: Tui, event: GetCustomTokensEvent) {.async, gcsafe,
  nimcall.} =

  # if TUI is not ready for output then ignore it
  if self.outputReady:
    if event.error != "":
      self.wprintFormatError(event.timestamp, event.error)
      return

    let tokens = event.tokens
    let timestamp = event.timestamp
    trace "TUI showing tokens", tokens=(%tokens)

    if tokens.len > 0:
      var i = 1
      self.printResult("Existing tokens:", timestamp)
      for token in tokens:
        let
          name = token.name
          symbol = token.symbol
          address = token.address

        self.printResult(fmt"{2.indent()}{i}. {name} ({symbol}): {address}", timestamp)
        i = i + 1
    else:
      self.printResult(
        "No custom tokens added.",
        timestamp)

# AddCustomTokenEvent ----------------------------------------------------------

proc action*(self: Tui, event: AddCustomTokenEvent) {.async, gcsafe,
  nimcall.} =

  # if TUI is not ready for output then ignore it
  if self.outputReady:
    if event.error != "":
      self.wprintFormatError(event.timestamp, event.error)
      return

    let
      name = event.name
      symbol = event.symbol
      address = event.address
      timestamp = event.timestamp

    self.printResult("Added a token:", timestamp)
    self.printResult(fmt"{2.indent()}{name} ({symbol}): {address}", timestamp)

# DeleteCustomTokenEvent -------------------------------------------------------

proc action*(self: Tui, event: DeleteCustomTokenEvent) {.async, gcsafe,
  nimcall.} =

  # if TUI is not ready for output then ignore it
  if self.outputReady:
    if event.error != "":
      self.wprintFormatError(event.timestamp, event.error)
      return

    let
      address = event.address
      timestamp = event.timestamp

    self.printResult("Deleted a token:", timestamp)
    self.printResult(fmt"{2.indent()}{address}", timestamp)

# GetPriceEvent ----------------------------------------------------------

proc action*(self: Tui, event: GetPriceEvent) {.async, gcsafe,
  nimcall.} =

  # if TUI is not ready for output then ignore it
  if self.outputReady:
    if event.error != "":
      self.wprintFormatError(event.timestamp, event.error)
      return

    let symbol = event.symbol
    let currency = event.currency
    let price = event.price
    let timestamp = event.timestamp
    trace "TUI showing token price from nim-status", symbol=(%symbol),
      currency=(%currency), price=(%price)

    self.printResult(fmt"{2.indent()} {symbol}/{currency}: {price}", timestamp)

# SetPriceTimeoutEvent ----------------------------------------------------------

proc action*(self: Tui, event: SetPriceTimeoutEvent) {.async, gcsafe,
  nimcall.} =

  # if TUI is not ready for output then ignore it
  if self.outputReady:
    if event.error != "":
      self.wprintFormatError(event.timestamp, event.error)
      return

    let timeout = event.timeout
    let timestamp = event.timestamp
    trace "TUI setting price update timeout from nim-status", timeout=(%timeout)

    self.printResult(
      fmt"Token prices will update every {timeout} seconds when logged in", timeout)


# ImportMnemonicEvent ----------------------------------------------------------

proc action*(self: Tui, event: ImportMnemonicEvent) {.async, gcsafe, nimcall.} =
  # if TUI is not ready for output then ignore it
  if self.outputReady:
    if event.error != "":
      self.wprintFormatError(event.timestamp, event.error)
      return

    let
      account = event.account
      timestamp = event.timestamp
      name = account.name
      keyUid = account.keyUid
      abbrev = keyUid[0..5] & "..." & keyUid[^4..^1]

    trace "TUI importing account" , account=account.encode

    self.printResult("Imported account:", timestamp)
    self.printResult(fmt"{2.indent()}{name} ({abbrev})", timestamp)

# JoinPublicChatEvent -------------------------------------------------------

proc action*(self: Tui, event: JoinPublicChatEvent) {.async, gcsafe, nimcall.} =
  let
    timestamp = event.timestamp
    id = event.id
    name = event.name

  if not self.client.chats.hasKey(id):
    self.client.chats[id] = name
    self.printResult(fmt"Joined chat: {name}", timestamp)
  else:
    self.printResult(fmt"Chat already joined: {name}", timestamp)
    
# JoinTopicEvent --------------------------------------------------------------

proc action*(self: Tui, event: JoinTopicEvent) {.async, gcsafe, nimcall.} =
  let
    timestamp = event.timestamp
    topic = event.topic

  if not self.client.topics.contains(topic):
    self.client.topics.incl(topic)
    self.printResult(fmt"Joined topic: {topic}", timestamp)
  else:
    self.printResult(fmt"Topic already joined: {topic}", timestamp)

# LeavePublicChatEvent ------------------------------------------------------

proc action*(self: Tui, event: LeavePublicChatEvent) {.async, gcsafe,
  nimcall.} =
  let
    timestamp = event.timestamp
    id = event.id

  if self.client.chats.hasKey(id):
    let chatName = self.client.chats[id]
    self.client.chats.del(id)
    self.printResult(fmt"Left chat: status#{chatName}", timestamp)
  else:
    self.printResult(fmt"chat not joined, no need to leave",
      timestamp)

# LeaveTopicEvent -------------------------------------------------------------

proc action*(self: Tui, event: LeaveTopicEvent) {.async, gcsafe,
  nimcall.} =
  let
    timestamp = event.timestamp
    topic = event.topic

  if self.client.topics.contains(topic):
    self.client.topics.excl(topic)
    self.printResult(fmt"Left topic: {topic}", timestamp)
  else:
    self.printResult(fmt"Topic not joined, no need to leave: {topic}",
      timestamp)

# ListAccountsEvent -----------------------------------------------------------

proc action*(self: Tui, event: ListAccountsEvent) {.async, gcsafe,
  nimcall.} =

  # if TUI is not ready for output then ignore it
  if self.outputReady:
    let
      accounts = event.accounts
      timestamp = event.timestamp

    trace "TUI showing accounts", accounts=(%accounts)

    if accounts.len > 0:
      var i = 1
      self.printResult("Existing accounts:", timestamp)
      for account in accounts:
        let
          name = account.name
          keyUid = account.keyUid
          abbrev = keyUid[0..5] & "..." & keyUid[^4..^1]

        self.printResult(fmt"{2.indent()}{i}. {name} ({abbrev})",
          timestamp)
        i = i + 1
    else:
      self.printResult(
        "No accounts. Create an account using `/create <password>`.",
        timestamp)

# ListWalletAccountsEvent ------------------------------------------------------

proc action*(self: Tui, event: ListWalletAccountsEvent) {.async, gcsafe,
  nimcall.} =

  # if TUI is not ready for output then ignore it
  if self.outputReady:
    if event.error != "":
      self.wprintFormatError(event.timestamp, event.error)
      return

    let
      accounts = event.accounts
      timestamp = event.timestamp

    trace "TUI showing wallet accounts", accounts=(%accounts)

    if accounts.len > 0:
      var i = 1
      self.printResult("Wallet accounts:", timestamp)
      for account in accounts:
        let
          name = account.name
          address = $account.address

        self.printResult(fmt"{2.indent()}{i}. {name} ({address})",
          timestamp)
        i = i + 1
    else:
      self.printResult(
        "No wallet accounts. Generate a wallet using `/add <name> <password>`.",
        timestamp)

# LoginEvent ------------------------------------------------------------------

proc action*(self: Tui, event: LoginEvent) {.async, gcsafe, nimcall.} =
  let
    error = event.error
    loggedin = event.loggedin

  if error != "":
    self.wprintFormatError(getTime().toUnix(), fmt"{error}")
  else:
    self.client.account = event.account
    self.printResult("Login successful.", getTime().toUnix())
    if not self.client.online:
      asyncSpawn self.client.connect(self.client.account.name)

  self.client.loggedin = loggedin
  trace "TUI updated client state", loggedin

# LogoutEvent -----------------------------------------------------------------

proc action*(self: Tui, event: LogoutEvent) {.async, gcsafe, nimcall.} =
  let
    error = event.error
    loggedin = event.loggedin

  if error != "":
    self.wprintFormatError(getTime().toUnix(), fmt"{error}")
  else:
    self.client.account = PublicAccount()
    self.printResult("Logout successful.", getTime().toUnix())
    if self.client.online:
      asyncSpawn self.client.disconnect()

  self.client.loggedin = loggedin
  trace "TUI updated client state", loggedin

# NetworkStatusEvent -----------------------------------------------------------

proc action*(self: Tui, event: NetworkStatusEvent) {.async, gcsafe, nimcall.} =
  let online = event.online

  self.client.online = online
  trace "TUI updated client state", online

# UserMessageEvent -------------------------------------------------------------

proc action*(self: Tui, event: UserMessageEvent) {.async, gcsafe, nimcall.} =
  # if TUI is not ready for output then ignore it
  if self.outputReady:
    let
      message = event.message
      timestamp = event.timestamp
      username = event.username

    var topic = event.topic
    let topicSplit = topic.split('/')

    # if event.topic is not a properly formatted waku v2 content topic then the
    # whole string will be passed to printMessage
    if topicSplit.len == 5 and topicSplit[0] == "":
      # for "/toy-chat/2/example/proto", topic would be "example"
      topic = topicSplit[3]

    debug "TUI received user message", message, timestamp, username
    self.printMessage(message, timestamp, username, topic)

# CallRpcEvent -----------------------------------------------------------------

proc action*(self: Tui, event: CallRpcEvent) {.async, gcsafe,
  nimcall.} =

  # if TUI is not ready for output then ignore it
  if self.outputReady:
    if event.error != "":
      self.wprintFormatError(event.timestamp, event.error)
      return

    trace "Displaying call result"

    let
      response = event.response
      timestamp = event.timestamp

    self.printResult(fmt"RPC method response: {response}", timestamp)

# SendTransactionEvent ---------------------------------------------------------

proc action*(self: Tui, event: SendTransactionEvent) {.async, gcsafe,
  nimcall.} =

  # if TUI is not ready for output then ignore it
  if self.outputReady:
    if event.error != "":
      self.wprintFormatError(event.timestamp, event.error)
      return

    let
      response = event.response
      timestamp = event.timestamp

    self.printResult(fmt"eth_sendTransaction response: {response}", timestamp)
