{.push raises: [Defect].}

import # std libs
  std/[json, tables, times]

import # vendor libs
  eth/keyfile/uuid, secp256k1

import # nim-status libs
  ../alias, ../accounts/[accounts, generator/generator, public_accounts],
  ./common, ../conversions, ../extkeys/[paths, types], ../identicon, ../settings

export
  accounts, alias, common, conversions, generator, identicon, paths,
  public_accounts, secp256k1, settings, types, uuid

type
  PublicAccountResult* = Result[PublicAccount, string]

proc storeDerivedAccounts(self: StatusObject, id: UUID, keyUid: string,
  paths: seq[KeyPath], password, dir: string,
  accountType: AccountType): PublicAccountResult {.raises: [Defect,
  ref IOError, ref KeyError, ref OSError, SqliteError, ValueError].} =

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


proc createAccount*(self: StatusObject, mnemonicPhraseLength: int,
  bip39Passphrase, password: string, dir: string): PublicAccountResult {.raises:
  [ref Exception, ref ValueError].} =

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

proc getAccounts*(self: StatusObject): seq[accounts.Account] {.raises:
  [Defect, SqliteError, UserDbError, ref ValueError].} =

  self.userDb.getAccounts()

proc getChatAccount*(self: StatusObject): accounts.Account {.raises:
  [Defect, ref AssertionError, SqliteError, UserDbError, ref UnpackError,
  ref ValueError].} =

  self.userDb.getChatAccount()

proc getPublicAccounts*(self: StatusObject): seq[PublicAccount] {.raises:
  [Defect, ref AssertionError, SqliteError, ref ValueError].} =

  self.accountsDb.getPublicAccounts()

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

proc saveAccount*(self: StatusObject, account: PublicAccount) {.raises:
  [Defect, SqliteError, ref ValueError].} =

  self.accountsDb.saveAccount(account)
