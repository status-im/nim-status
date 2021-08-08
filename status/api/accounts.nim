{.push raises: [Defect].}

import # std libs
  std/[json, re, tables, times]

import # vendor libs
  eth/keyfile/uuid, secp256k1

import # status modules
  ../private/accounts/[accounts, public_accounts],
  ../private/accounts/generator/[account, generator],
  ../private/[alias, conversions, identicon, settings],
  ../private/extkeys/[paths, types],
  ./common

export
  common, public_accounts
  # TODO: are these exports needed?
  #   accounts, alias, conversions, generator, identicon, paths,
  #   public_accounts, secp256k1, settings, types, uuid

type
  PublicAccountResult* = Result[PublicAccount, string]

  PublicAccountsResult* = Result[seq[PublicAccount], string]

  ChatAccountResult* = Result[accounts.Account, string]

proc storeDerivedAccounts(self: StatusObject, id: UUID, keyUid: string,
  paths: seq[KeyPath], password, dir: string,
  accountType: AccountType): PublicAccountResult =

  let accountInfos = ?self.accountsGenerator.storeDerivedAccounts(id, paths,
      password, dir)
  var whisperAcct: AccountInfo
  try:
    whisperAcct = accountInfos[PATH_WHISPER]
  except KeyError as e:
    return PublicAccountResult.err "Error getting whisper account from " &
      "derived accounts: " & e.msg

  let
    alias = try: whisperAcct.publicKey.generateAlias
            except RegexError as e:
              return PublicAccountResult.err "Error generating alias for " &
                "public key: " & e.msg
    pubAccount = PublicAccount(
      creationTimestamp: getTime().toUnix,
      name: alias,
      identicon: whisperAcct.publicKey.identicon(),
      keycardPairing: "",
      keyUid: keyUid # whisper key-uid
    )
  try:
    self.accountsDb.saveAccount(pubAccount)
  except PublicAccountDbError as e:
    return PublicAccountResult.err "Failed to store derived accounts: " & e.msg

  let
    defaultWalletAccountDerived =
      try: accountInfos[PATH_DEFAULT_WALLET]
      except KeyError as e:
        return PublicAccountResult.err "Error getting default wallet from " &
          "derived accounts: " & e.msg
    defaultWalletPubKeyResult =
      SkPublicKey.fromHex(defaultWalletAccountDerived.publicKey)
    whisperAccountPubKeyResult =
      SkPublicKey.fromHex(whisperAcct.publicKey)

  if defaultWalletPubKeyResult.isErr:
    return PublicAccountResult.err $defaultWalletPubKeyResult.error
  if whisperAccountPubKeyResult.isErr:
    return PublicAccountResult.err $whisperAccountPubKeyResult.error

  const errorMsg = "Error creating default wallet account and whisper account: "
  try:
    let
      defaultWalletAccount = accounts.Account(
        address: defaultWalletAccountDerived.address.parseAddress,
        wallet: true.some,
        chat: false.some,
        `type`: some($accountType),
        storage: STORAGE_ON_DEVICE.some,
        path: PATH_DEFAULT_WALLET.some,
        publicKey: defaultWalletPubKeyResult.get.some,
        name: "Status account".some,
        color: "#4360df".some
      )
      whisperAccount = accounts.Account(
        address: whisperAcct.address.parseAddress,
        wallet: false.some,
        chat: true.some,
        `type`: some($accountType),
        storage: STORAGE_ON_DEVICE.some,
        path: PATH_WHISPER.some,
        publicKey: whisperAccountPubKeyResult.get.some,
        name: pubAccount.name.some,
        color: "#4360df".some
      )

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
  except AccountDbError as e:
    return PublicAccountResult.err errorMsg & e.msg
  except StatusApiError as e:
    return PublicAccountResult.err errorMsg & e.msg
  except ValueError as e:
    return PublicAccountResult.err "Error parsing address of default wallet " &
      "account: " & e.msg


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
      password, dir, AccountType.Generated)
    uuidResult = uuidGenerate()

  if uuidResult.isErr:
    return PublicAccountResult.err "Error generating uuid: " & $uuidResult.error

  const nodeConfigJsonError = "Error parsing node config json: "
  var
    settings: Settings
    nodeConfig: JsonNode
  try:
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
    # TODO: a proper node config needs to
    # be created and stored on login (fleet info should be downloaded on login)
    nodeConfig = NODE_CONFIG.parseJson
  except JsonParsingError as e:
    return PublicAccountResult.err nodeConfigJsonError & e.msg
  except KeyError as e:
    return PublicAccountResult.err "Error getting account from derived " &
      "accounts: " & e.msg
  except ValueError as e:
    return PublicAccountResult.err "Error parsing an address: " & e.msg
  except Exception as e: # raised by parseJson
    return PublicAccountResult.err nodeConfigJsonError & e.msg

  const errorMsg = "Error creating account: "
  try:
    self.userDb.createSettings(settings, nodeConfig)
    self.closeUserDb()
  except SettingDbError as e:
    return PublicAccountResult.err errorMsg & e.msg
  except StatusApiError as e:
    return PublicAccountResult.err errorMsg & e.msg

  PublicAccountResult.ok(pubAccount)

proc getChatAccount*(self: StatusObject): ChatAccountResult =
  try:
    return ChatAccountResult.ok self.userDb.getChatAccount()
  except AccountDbError as e:
    return ChatAccountResult.err e.msg
  except StatusApiError as e:
    return ChatAccountResult.err e.msg

proc getPublicAccounts*(self: StatusObject): PublicAccountsResult =
  try:
    PublicAccountsResult.ok self.accountsDb.getPublicAccounts()
  except PublicAccountDbError as e:
    return PublicAccountsResult.err "Failed to get public accounts: " & e.msg


proc importMnemonic*(self: StatusObject, mnemonic: Mnemonic,
  bip39Passphrase, password: string, dir: string): PublicAccountResult =

  try:
    let
      imported = ?self.accountsGenerator.importMnemonic(mnemonic,
        bip39Passphrase)
      paths = @[PATH_WALLET_ROOT, PATH_EIP_1581, PATH_WHISPER,
        PATH_DEFAULT_WALLET]
      pubAccount = ?self.storeDerivedAccounts(imported.id, imported.keyUid,
        paths, password, dir, AccountType.Seed)
    PublicAccountResult.ok(pubAccount)
  except Exception as e:
    return PublicAccountResult.err e.msg

proc saveAccount*(self: StatusObject, account: PublicAccount):
  PublicAccountResult =

  try:
    self.accountsDb.saveAccount(account)
    return PublicAccountResult.ok account
  except PublicAccountDbError as e:
    return PublicAccountResult.err "Failed to save account: " & e.msg
