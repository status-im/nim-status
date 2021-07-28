import # std libs
  std/[strformat, strutils]

import # vendor libs
  web3/conversions

import # chat libs
  ./parser

export parser

logScope:
  topics = "chat tui"

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
  KEY_MOUSE = "KEY_MOUSE"
  KEY_RESIZE = "KEY_RESIZE"

proc dispatch*(self: ChatTUI, command: string) {.gcsafe, nimcall.} =
  let (commandType, args, isCommand) = parse(command)

  if isCommand: commandCases()
  else:
    # should print an error/explanation to the screen as well
    error "TUI received malformed or unknown command", command

# InputKey ---------------------------------------------------------------------

proc action*(self: ChatTUI, event: InputKey) {.async, gcsafe, nimcall.} =
  # if TUI is not ready for input then ignore it
  if self.inputReady:
    # handle mouse events and special keys e.g. arrow keys, ESCAPE, RETURN, etc.
    let
      key = event.key
      name = event.name

    case name:
      of ESCAPE:
        discard

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

proc action*(self: ChatTUI, event: InputReady) {.async, gcsafe, nimcall.} =
  let
    ready = event.ready

  if ready:
    self.inputReady = true
    self.drawScreen()
    self.outputReady = true

# InputString ------------------------------------------------------------------

proc action*(self: ChatTUI, event: InputString) {.async, gcsafe, nimcall.} =
  # if TUI is not ready for input then ignore it
  if self.inputReady:
    let input = event.str
    self.currentInput = self.currentInput & input
    trace "TUI updated current input", currentInput=self.currentInput

    self.printInput(input)

# AddWalletAccountEvent --------------------------------------------------------

proc action*(self: ChatTUI, event: AddWalletAccountEvent) {.async, gcsafe,
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

# CreateAccountEvent ----------------------------------------------------------

proc action*(self: ChatTUI, event: CreateAccountEvent) {.async, gcsafe,
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

# GetCustomTokensEvent ----------------------------------------------------------

proc action*(self: ChatTUI, event: GetCustomTokensEvent) {.async, gcsafe,
  nimcall.} =
  discard

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

proc action*(self: ChatTUI, event: AddCustomTokenEvent) {.async, gcsafe,
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


# DeleteCustomTokenEvent ----------------------------------------------------------

proc action*(self: ChatTUI, event: DeleteCustomTokenEvent) {.async, gcsafe,
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

# ImportMnemonicEvent ----------------------------------------------------------

proc action*(self: ChatTUI, event: ImportMnemonicEvent) {.async, gcsafe, nimcall.} =
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

# JoinTopicEvent --------------------------------------------------------------

proc action*(self: ChatTUI, event: JoinTopicEvent) {.async, gcsafe, nimcall.} =
  let
    timestamp = event.timestamp
    topic = event.topic

  if not self.client.topics.contains(topic):
    self.client.topics.incl(topic)
    self.printResult(fmt"Joined topic: {topic}", timestamp)
  else:
    self.printResult(fmt"Topic already joined: {topic}", timestamp)

# LeaveTopicEvent -------------------------------------------------------------

proc action*(self: ChatTUI, event: LeaveTopicEvent) {.async, gcsafe,
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

proc action*(self: ChatTUI, event: ListAccountsEvent) {.async, gcsafe,
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

proc action*(self: ChatTUI, event: ListWalletAccountsEvent) {.async, gcsafe,
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

proc action*(self: ChatTUI, event: LoginEvent) {.async, gcsafe, nimcall.} =
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

proc action*(self: ChatTUI, event: LogoutEvent) {.async, gcsafe, nimcall.} =
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

proc action*(self: ChatTUI, event: NetworkStatusEvent) {.async, gcsafe, nimcall.} =
  let online = event.online

  self.client.online = online
  trace "TUI updated client state", online

# UserMessageEvent -------------------------------------------------------------

proc action*(self: ChatTUI, event: UserMessageEvent) {.async, gcsafe, nimcall.} =
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
