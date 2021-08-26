import # client modules
  ../client, ./ncurses_helpers

import # vendor libs
  eth/common

export client, ncurses_helpers

logScope:
  topics = "tui"

type
  Tui* = ref object
    client*: Client
    clientConfig*: ClientConfig
    currentInput*: string
    events*: EventChannel
    infoLine*: PWindow
    infoLineBottom*: PWindow
    inputReady*: bool
    inputWin*: PWindow
    inputWinBox*: PWindow
    locale*: string
    mainWin*: PWindow
    mouse*: bool
    outputReady*: bool
    outputWin*: PWindow
    outputWinBox*: PWindow
    running*: bool
    taskRunner*: TaskRunner

  TuiEvent* = ref object of Event

  InputKey* = ref object of TuiEvent
    key*: int
    name*: string

  InputReady* = ref object of TuiEvent
    ready*: bool

  InputString* = ref object of TuiEvent
    str*: string

  # all fields on types that derive from Command should be of type `string`
  Command* = ref object of RootObj

  AddCustomToken* = ref object of Command
    address*: string
    name*: string
    symbol*: string
    color*: string
    decimals*: string

  AddWalletAccount* = ref object of Command
    name*: string
    password*: string

  AddWalletPrivateKey* = ref object of Command
    name*: string
    password*: string
    privateKey*: string

  AddWalletSeed* = ref object of Command
    bip39Passphrase*: string
    name*: string
    mnemonic*: string
    password*: string

  AddWalletWatchOnly* = ref object of Command
    name*: string
    address*: string

  CallRpc* = ref object of Command
    rpcMethod*: string
    params*: string

  Connect* = ref object of Command

  CommandParameter* = ref object of RootObj
    name*: string
    description*: string

  CreateAccount* = ref object of Command
    password*: string

  DeleteCustomToken* = ref object of Command
    index*: string

  DeleteWalletAccount* = ref object of Command
    accountIndex*: string
    password*: string

  Disconnect* = ref object of Command

  GetAssets* = ref object of Command
    owner*: string

  GetCustomTokens* = ref object of Command

  GetPrice* = ref object of Command
    tokenSymbol*: string
    fiatCurrency*: string

  Help* = ref object of Command
    command*: string

  HelpText* = ref object of RootObj
    command*: string
    parameters*: seq[CommandParameter]
    aliases*: seq[string]
    description*: string

  ImportMnemonic* = ref object of Command
    mnemonic*: string
    passphrase*: string
    password*: string

  JoinPublicChat* = ref object of Command
    name*: string

  LeavePublicChat* = ref object of Command
    name*: string

  JoinTopic* = ref object of Command
    topic*: string

  LeaveTopic* = ref object of Command
    topic*: string

  ListAccounts* = ref object of Command

  ListWalletAccounts* = ref object of Command

  ListTopics* = ref object of Command

  Login* = ref object of Command
    account*: string
    password*: string

  Logout* = ref object of Command

  Quit* = ref object of Command

  SendMessage* = ref object of Command
    message*: string

  SendTransaction* = ref object of Command
    fromAddress*: string
    toAddress*: string
    value*: string
    maxPriorityFee*: string
    maxFee*: string
    gasLimit*: string
    payload*: string
    nonce*: string
    password*: string
    
  SetPriceTimeout* = ref object of Command
    timeout*: string

const
  TuiEvents* = [
    "InputKey",
    "InputReady",
    "InputString"
  ]

  DEFAULT_COMMAND* = ""

  commands* = {
    DEFAULT_COMMAND: "SendMessage",
    "addcustomtoken": "AddCustomToken",
    "addwallet": "AddWalletAccount",
    "addwalletpk": "AddWalletPrivateKey",
    "addwalletseed": "AddWalletSeed",
    "addwalletwatch": "AddWalletWatchOnly",
    "call": "CallRpc",
    "connect": "Connect",
    "createaccount": "CreateAccount",
    "deletecustomtoken": "DeleteCustomToken",
    "deletewalletaccount": "DeleteWalletAccount",
    "disconnect": "Disconnect",
    "getassets": "GetAssets",
    "getcustomtokens": "GetCustomTokens",
    "getprice": "GetPrice",
    "help": "Help",
    "importmnemonic": "ImportMnemonic",
    "joinpublicchat": "JoinPublicChat",
    "jointopic": "JoinTopic",
    "leavepublicchat": "LeavePublicChat",
    "leavetopic": "LeaveTopic",
    "listaccounts": "ListAccounts",
    "listwalletaccounts": "ListWalletAccounts",
    "listtopics": "ListTopics",
    "login": "Login",
    "logout": "Logout",
    "sendtransaction": "SendTransaction",
    "setpricetimeout": "SetPriceTimeout",
    "quit": "Quit"
  }.toTable

  aliases* = {
    "?": "help",
    "add": "addwallet",
    "addpk": "addwalletpk",
    "addseed": "addwalletseed",
    "addtoken": "addcustomtoken",
    "addwatch": "addwalletwatch",
    "assets": "getassets",
    "create": "createaccount",
    "delete": "deletewalletaccount",
    "deletetoken": "deletecustomtoken",
    "gettokens": "getcustomtokens",
    "import": "importmnemonic",
    "join": "jointopic",
    "leave": "leavetopic",
    "list": "listaccounts",
    "listwallets": "listwalletaccounts",
    "part": "leavetopic",
    "rpc": "call",
    "send": DEFAULT_COMMAND,
    "sub": "jointopic",
    "subscribe": "jointopic",
    "topics": "listtopics",
    "trx": "sendtransaction",
    "unjoin": "leavetopic",
    "unsub": "leavetopic",
    "unsubscribe": "leavetopic",
    "wallets": "listwalletaccounts"
  }.toTable

  aliased* = {
    DEFAULT_COMMAND: @["send"],
    "addcustomtoken": @["addtoken"],
    "addwallet": @["add"],
    "addwalletpk": @["addpk"],
    "addwalletseed": @["addseed"],
    "addwalletwatch": @["addwatch"],
    "call": @["rpc"],
    "createaccount": @["create"],
    "deletecustomtoken": @["deletetoken"],
    "deletewalletaccount": @["delete"],
    "getassets": @["assets"],
    "getcustomtokens": @["gettokens"],
    "importmnemonic": @["import"],
    "help": @["?"],
    "jointopic": @["join", "sub", "subscribe"],
    "leavetopic": @["leave", "part", "unjoin", "unsub", "unsubscribe"],
    "listaccounts": @["list"],
    "listtopics": @["topics"],
    "listwalletaccounts": @["listwallets", "wallets"],
    "sendtransaction": @["trx"]
  }.toTable

proc stop*(self: Tui) {.async.} =
  debug "TUI stopping"

  var stopping: seq[Future[void]] = @[]
  stopping.add self.client.stop()
  stopping.add self.taskRunner.stop()
  await allFutures(stopping)
  self.events.close()

  # calling `endwin` here isn't working as expected, i.e. if the terminal is
  # resized while the client program is running then the terminal's state is
  # often "corrupted" when the client program exits; calling `endwin` before
  # program exit is supposed to prevent it from being corrupted
  endwin()
  trace "TUI restored the terminal"

  debug "TUI stopped"
  # set `self.running = true` as the the last step to facilitate clean program
  # exit (see ../../client.nim)
  self.running = false
