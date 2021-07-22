import # nim libs
  std/[os, json, sequtils, strformat, strutils, sugar, tables, times,
    typetraits]

import # vendor libs
  confutils, eth/[keyfile/uuid, keys], json_serialization, secp256k1, sqlcipher,
  stew/results, web3/ethtypes

import # nim-status libs
  ./accounts/[accounts, public_accounts],
  ./accounts/generator/[generator, utils],
  ./accounts/generator/account as generator_account, ./alias, ./chats,
  ./conversions, ./database, ./extkeys/[hdkey, mnemonic, paths, types],
  ./identicon, ./settings, ./settings/types as settings_types, ./util

export results

type
  CreateSettingsResult* = Result[void, string]

  GetSettingsResult* = Result[Settings, string]

  LoginResult* = Result[PublicAccount, string]

  LogoutResult* = Result[void, string]

  PublicAccountResult* = Result[PublicAccount, string]

  StatusObject* = ref object
    accountsGenerator*: Generator
    accountsDb: DbConn
    dataDir*: string
    userDbConn: DbConn
      # Do not use self.userDbConn directly in exported procs. Use self.userDb,
      # self.initUserDb, self.closeUserDb, and self.isLoggedIn instead.

  WalletAccount* = ref object
    address*: Address
    name*: string

  WalletAccountResult* = Result[accounts.Account, string]

  WalletAccountsResult* = Result[seq[WalletAccount], string]

proc new*(T: type StatusObject, dataDir: string,
  accountsDbFileName: string = "accounts.sql"): T =

  T(accountsDb: initializeDB(dataDir / accountsDbFileName),
    dataDir: dataDir, accountsGenerator: Generator.new())

proc userDb(self: StatusObject): DbConn =
  if distinctBase(self.userDbConn).isNil:
    raise newException(IOError,
      "User DB not initialized. Please login first.")
  self.userDbConn

proc closeUserDb(self: StatusObject) =
  self.userDb.close()
  self.userDbConn = nil

proc isLoggedIn*(self: StatusObject): bool =
  not distinctBase(self.userDbConn).isNil

proc close*(self: StatusObject) =
  if self.isLoggedIn:
    self.closeUserDb()
  self.accountsDb.close()

proc initUserDb(self: StatusObject, keyUid, password: string) =
  self.userDbConn = initializeDB(self.dataDir / keyUid & ".db", password)

proc storeWalletAccount(self: StatusObject, name: string, address: Address,
  publicKey: Option[SkPublicKey], accountType: AccountType,
  path: KeyPath): WalletAccountResult =

  var walletName = name
  if walletName == "":
    let walletAccts {.used.} = self.userDb.getWalletAccounts()
    walletName = fmt"Wallet account {walletAccts.len}"

  let
    walletAccount = accounts.Account(
      address: address,
      wallet: false.some, # NOTE: this *should* be true, however in status-go,
      # only the wallet root account is true, and there is a unique db
      # constraint enforcing only one account to have wallet = true
      chat: false.some,
      `type`: ($accountType).some,
      storage: string.none,
      path: path.some,
      publicKey: publicKey,
      name: walletName.some,
      color: "#4360df".some # TODO: pass in colour
    )
  self.userDb.createAccount(walletAccount)

  return WalletAccountResult.ok(walletAccount)

proc storeDerivedAccount(self: StatusObject, id: UUID, path: KeyPath, name,
  password, dir: string, accountType: AccountType): WalletAccountResult =

  let
    accountInfos = ?self.accountsGenerator.storeDerivedAccounts(id, @[path],
      password, dir)
    acct = accountInfos[path]

  let walletPubKeyResult = SkPublicKey.fromHex(acct.publicKey)

  if walletPubKeyResult.isErr:
    return WalletAccountResult.err $walletPubKeyResult.error

  let
    address = acct.address.parseAddress
    publicKey = walletPubKeyResult.get.some

  return self.storeWalletAccount(name, address, publicKey, accountType, path)

proc storeDerivedAccounts(self: StatusObject, id: UUID, keyUid: string,
  paths: seq[KeyPath], password, dir: string): PublicAccountResult =

  let
    accountInfos = ?self.accountsGenerator.storeDerivedAccounts(id, paths,
      password, dir)
    whisperAcct = accountInfos[PATH_WHISPER]
    pubAccount = PublicAccount(
      creationTimestamp: getTime().toUnix,
      name: whisperAcct.publicKey.generateAlias(),
      identicon: whisperAcct.publicKey.identicon(),
      keycardPairing: "",
      keyUid: keyUid # whisper key-uid
    )

  self.accountsDb.saveAccount(pubAccount)

  let
    defaultWalletAccountDerived = accountInfos[PATH_DEFAULT_WALLET]
    defaultWalletPubKeyResult =
      SkPublicKey.fromHex(defaultWalletAccountDerived.publicKey)
    whisperAccountPubKeyResult =
      SkPublicKey.fromHex(whisperAcct.publicKey)

  if defaultWalletPubKeyResult.isErr:
    return PublicAccountResult.err $defaultWalletPubKeyResult.error
  if whisperAccountPubKeyResult.isErr:
    return PublicAccountResult.err $whisperAccountPubKeyResult.error

  let
    defaultWalletAccount = accounts.Account(
      address: defaultWalletAccountDerived.address.parseAddress,
      wallet: true.some,
      chat: false.some,
      `type`: some($AccountType.Seed),
      storage: string.none,
      path: PATH_DEFAULT_WALLET.some,
      publicKey: defaultWalletPubKeyResult.get.some,
      name: "Status account".some,
      color: "#4360df".some
    )
    whisperAccount = accounts.Account(
      address: whisperAcct.address.parseAddress,
      wallet: false.some,
      chat: true.some,
      `type`: some($AccountType.Seed),
      storage: string.none,
      path: PATH_WHISPER.some,
      publicKey: whisperAccountPubKeyResult.get.some,
      name: pubAccount.name.some,
      color: "#4360df".some
    )

  try:
    # We need an inited user db to create accounts, which requires a login.
    # First, record if we are currently logged in, and then init the user db
    # if not. After we know the db has been inited, create the needed accounts.
    # Once finished, close the db if we were originally logged out.
    let wasLoggedIn = self.isLoggedIn
    if not wasLoggedIn:
      self.initUserDb(keyUid, password)

    self.userDb.createAccount(defaultWalletAccount)
    self.userDb.createAccount(whisperAccount)

    if not wasLoggedIn:
      self.closeUserDb()

    return PublicAccountResult.ok(pubAccount)
  except Exception as e:
    return PublicAccountResult.err e.msg

proc validatePassword(self: StatusObject, password, dir: string): bool =

  let address = self.userDb.getSetting(string, SettingsCol.WalletRootAddress)
  if address.isNone:
    return false
  let loadAcctResult = self.accountsGenerator.loadAccount(
    address.get.parseAddress, password, dir)
  return loadAcctResult.isOk

proc storeImportedWalletAccount(self: StatusObject, privateKey: SkSecretKey,
  name, password, dir: string, accountType: AccountType): WalletAccountResult =

  try:
    if not self.validatePassword(password, dir):
      return WalletAccountResult.err "Invalid password"

    discard ?self.accountsGenerator.storeKeyFile(privateKey, password, dir)

    let
      path = PATH_DEFAULT_WALLET # NOTE: this is the keypath
        # given to imported wallet accounts in status-desktop
      publicKey = privateKey.toPublicKey.some
      address = privateKey.toAddress
    return self.storeWalletAccount(name, address, publicKey, accountType, path)

  except Exception as e:
    return WalletAccountResult.err e.msg

proc addWalletAccount*(self: StatusObject, name, password,
  dir: string): WalletAccountResult =

  if not self.isLoggedIn:
    return WalletAccountResult.err "Not logged in. You must be logged in to " &
      "create a new wallet account."

  let address = self.userDb.getSetting(string, SettingsCol.WalletRootAddress)
  if address.isNone:
    return WalletAccountResult.err "Unable to get wallet root address from " &
      "settings. Cannot create a derived wallet."

  let
    lastDerivedPathIdx =
      self.userDb.getSetting(int, SettingsCol.LatestDerivedPath, 0)
    loadedAccount = ?self.accountsGenerator.loadAccount(
      address.get.parseAddress, password, dir)
    newIdx = lastDerivedPathIdx + 1
    path = fmt"{PATH_WALLET_ROOT}/{newIdx}"
    walletAccount = ?self.storeDerivedAccount(loadedAccount.id, KeyPath path,
      name, password, dir, AccountType.Generated)

  self.userDb.saveSetting(SettingsCol.LatestDerivedPath, newIdx)

  WalletAccountResult.ok(walletAccount)

proc addWalletPrivateKey*(self: StatusObject, privateKeyHex: string,
  name, password, dir: string): WalletAccountResult =

  try:
    var privateKeyStripped = privateKeyHex
    privateKeyStripped.removePrefix("0x")

    let secretKeyResult = SkSecretKey.fromHex(privateKeyStripped)
    if secretKeyResult.isErr:
      return WalletAccountResult.err $secretKeyResult.error

    return self.storeImportedWalletAccount(secretKeyResult.get, name, password,
      dir, AccountType.Key)

  except Exception as e:
    return WalletAccountResult.err e.msg

proc addWalletSeed*(self: StatusObject, mnemonic: Mnemonic, name, password,
  dir, bip39Passphrase: string): WalletAccountResult =

  try:
    if not self.validatePassword(password, dir):
      return WalletAccountResult.err "Invalid password"

    let imported = ?self.accountsGenerator.importMnemonic(mnemonic,
      bip39Passphrase)

    return self.storeDerivedAccount(imported.id, PATH_DEFAULT_WALLET, name,
      password, dir, AccountType.Seed)

  except Exception as e:
    return WalletAccountResult.err e.msg

proc addWalletWatchOnly*(self: StatusObject, address: Address,
  name: string): WalletAccountResult =

  try:
    return self.storeWalletAccount(name, address, SkPublicKey.none,
      AccountType.Watch, PATH_DEFAULT_WALLET)

  except Exception as e:
    return WalletAccountResult.err e.msg

proc createAccount*(self: StatusObject, mnemonicPhraseLength: int,
  bip39Passphrase, password: string, dir: string): PublicAccountResult =

  if self.isLoggedIn:
    return PublicAccountResult.err "Already logged in. Must be logged out to " &
      "create a new account."

  let
    n = 1 # hardcode only one account being created
    paths = @[PATH_WALLET_ROOT, PATH_EIP_1581, PATH_WHISPER, PATH_DEFAULT_WALLET]
    accounts = ?self.accountsGenerator.generateAndDeriveAddresses(
      mnemonicPhraseLength, n, bip39Passphrase, paths)
    account = accounts[n - 1]

  self.initUserDb(account.keyUid, password)
  let
    pubAccount = ?self.storeDerivedAccounts(account.id, account.keyUid, paths,
      password, dir)
    uuidResult = uuidGenerate()

  if uuidResult.isErr:
    return PublicAccountResult.err "Error generating uuid: " & $uuidResult.error

  let
    settings = Settings(
      keyUid: account.keyUid,
      mnemonic: (string account.mnemonic).some,
      publicKey: account.derived[PATH_WHISPER].publicKey,
      name: pubAccount.name.some,
      userAddress: account.address.parseAddress,
      eip1581Address: account.derived[PATH_EIP_1581].address.parseAddress,
      dappsAddress: account.derived[PATH_DEFAULT_WALLET].address.parseAddress,
      walletRootAddress:
        account.derived[PATH_WALLET_ROOT].address.parseAddress.some,
      previewPrivacy: true,
      signingPhrase: generateSigningPhrase(3),
      logLevel: "INFO".some, # TODO: how can we use the runtime LogLevel setting?
      latestDerivedPath: 0,
      networks: DEFAULT_NETWORKS,
      currency: "usd".some, # TODO: move to constants
      photoPath: pubAccount.identicon, # TODO: change photoPath to identicon
      wakuEnabled: true.some,
      walletVisibleTokens: (%* {
        "mainnet": ["SNT"]
      }).some,
      appearance: 0,
      currentNetwork: DEFAULT_NETWORK_NAME,
      installationID: $(uuidResult.get)
    )
    nodeConfig = NODE_CONFIG.parseJson # TODO: a proper node config needs to
    # be created and stored on login (fleet info should be downloaded on login)

  self.userDb.createSettings(settings, nodeConfig)
  self.closeUserDb()

  PublicAccountResult.ok(pubAccount)

# TODO: Remove this from the client if not needed. This is only used for tests
# right now.
proc createSettings*(self: StatusObject, settings: Settings,
  nodeConfig: JsonNode): CreateSettingsResult =

  if not self.isLoggedIn:
    return CreateSettingsResult.err "Not logged in. You must be logged in to " &
      "create settings."
  try:
    self.userDb.createSettings(settings, nodeConfig)
    return CreateSettingsResult.ok
  except Exception as e:
    return CreateSettingsResult.err e.msg

proc getAccounts*(self: StatusObject): seq[accounts.Account] =
  self.userDb.getAccounts()

proc getChatAccount*(self: StatusObject): accounts.Account =
  self.userDb.getChatAccount()

proc getPublicAccounts*(self: StatusObject): seq[PublicAccount] =
  self.accountsDb.getPublicAccounts()

proc toWalletAccount(account: accounts.Account): WalletAccount {.used.} =
  let name = if account.name.isNone: "" else: account.name.get
  WalletAccount(address: account.address, name: name)

proc getWalletAccounts*(self: StatusObject): WalletAccountsResult =
  if not self.isLoggedIn:
    return WalletAccountsResult.err "Not logged in. Must be logged in to get " &
      "wallet accounts."
  try:
    let accounts = self.userDb.getWalletAccounts().map(a => a.toWalletAccount)
    return WalletAccountsResult.ok accounts
  except Exception as e:
    return WalletAccountsResult.err "Error getting wallet accounts: " & e.msg

# proc getSetting*[T](self: StatusObject, U: typedesc[T],
#   setting: SettingsCol): GetSettingResult[T] =

#   if not self.isLoggedIn:
#     return GetSettingResult.err "Not logged in. Must be logged in to get " &
#       "settings."
#   try:
#     let opt = self.userDb.getSetting(U, setting)
#     if opt.isNone:
#       return GetSettingResult.err "asdf"
#     return GetSettingResult.ok opt.get
#   except Exception as e:
#     return GetSettingResult.err e.msg

# proc getSetting*[T](self: StatusObject, U: typedesc[T], setting: SettingsCol,
#   defaultValue: T): GetSettingResult[T] =

#   if not self.isLoggedIn:
#     return GetSettingResult.err "Not logged in. Must be logged in to get " &
#       "settings."
#   try:
#     let opt = self.userDb.getSetting(U, setting)
#     if opt.isNone:
#       return GetSettingResult.err "asdf"
#     return GetSettingResult.ok opt.get
#   except Exception as e:
#     return GetSettingResult.err e.msg

proc getSettings*(self: StatusObject): GetSettingsResult =
  if not self.isLoggedIn:
    return GetSettingsResult.err "Not logged in. Must be logged in to get " &
      "settings."
  try:
    return GetSettingsResult.ok self.userDb.getSettings()
  except Exception as e:
    return GetSettingsResult.err e.msg

proc importMnemonic*(self: StatusObject, mnemonic: Mnemonic,
  bip39Passphrase, password: string, dir: string): PublicAccountResult =

  try:
    let
      imported = ?self.accountsGenerator.importMnemonic(mnemonic,
        bip39Passphrase)
      paths = @[PATH_WALLET_ROOT, PATH_EIP_1581, PATH_WHISPER,
        PATH_DEFAULT_WALLET]
      pubAccount = ?self.storeDerivedAccounts(imported.id, imported.keyUid,
        paths, password, dir)
    PublicAccountResult.ok(pubAccount)
  except Exception as e:
    return PublicAccountResult.err e.msg

proc loadChats*(self: StatusObject): seq[Chat] =
  getChats(self.userDb)

proc login*(self: StatusObject, keyUid, password: string): LoginResult =
  if self.isLoggedIn:
    return LoginResult.err "Already logged in"

  let account = self.accountsDb.getPublicAccount(keyUid)
  if account.isNone:
    return LoginResult.err "Could not find account with keyUid " & keyUid
  try:
    self.initUserDb(keyUid, password)
    LoginResult.ok account.get
  except Exception as e:
    if e.msg.contains "file is not a database":
      return LoginResult.err "Invalid password"
    return LoginResult.err "Failed to login, error: " & e.msg

proc logout*(self: StatusObject): LogoutResult =
  try:
    self.closeUserDb()
    LogoutResult.ok
  except Exception as e:
    return LogoutResult.err e.msg

proc saveAccount*(self: StatusObject, account: PublicAccount) =
  self.accountsDb.saveAccount(account)

proc updateAccountTimestamp*(self: StatusObject, timestamp: int64,
  keyUid: string) =

  self.accountsDb.updateAccountTimestamp(timestamp, keyUid)
