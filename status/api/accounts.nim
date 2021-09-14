{.push raises: [Defect].}

import # std libs
  std/[json, re, tables, times]

import # vendor libs
  eth/keyfile/uuid, secp256k1

import # status modules
  ../private/accounts/[accounts, public_accounts],
  ../private/accounts/generator/[account, generator],
  ../private/[alias, conversions, identicon, settings, util],
  ../private/extkeys/[paths, types],
  ./common

export common except setLoginState, setNetworkState
export public_accounts
# TODO: are these exports needed?
#   accounts, alias, conversions, generator, identicon, paths,
#   public_accounts, secp256k1, settings, types, uuid

type
  AccountsError* = enum
    ChatAcctNotFound        = "accts: chat account not found in derived " &
                                "accounts"
    CloseDbError            = "accts: error closing user db"
    CreateAcctError         = "accts: error creating account in the database"
    CreateSettingsError     = "accts: error creating settings in the database"
    DefWalletAcctNotFound   = "accts: default wallet account not found in " &
                                "derived accounts"
    Eip1581AcctNotFound     = "accts: EIP-1581 account not found in " &
                                "derived accounts"
    GenerateAliasError      = "accts: error generating alias for public key"
    GenerateDeriveError     = "accts: error generating and deriving addresses"
    GenerateIdenticonError  = "accts: error generating identicon from " &
                                "public key"
    GenerateUuidError       = "accts: error generating uuid"
    GetChatAcctError        = "accts: error getting chat account from the " &
                                "database"
    GetPublicAcctsError     = "accts: error getting public account(s) from " &
                                "the database"
    ImportMnemonicFailure   = "accts: failed to import mnemonic"
    InitUserDbError         = "accts: error initialising user db"
    InvalidPassword         = "accts: invalid password"
    InvalidPublicKey        = "accts: provided hex is not a valid public key"
    MustBeLoggedOut         = "accts: operation not permitted, must be " &
                                "logged out"
    ParseAddressError       = "accts: failed to parse address from given hex"
    ParseNodeConfigError    = "accts: error parsing node config json"
    SaveAccountsError       = "accts: error saving accounts to the database"
    StoreDerivedAcctsError  = "accts: error generating and storing derived " &
                                "accounts"
    UserDbError             = "accts: user DB error, must be logged in"
    UnknownError            = "accts: unknown error"
    WalletRootAcctNotFound  = "accts: wallet root account not found in " &
                                "derived accts"

  AccountsResult*[T] = Result[T, AccountsError]

proc storeDerivedAccounts(self: StatusObject, id: UUID, keyUid: string,
  paths: seq[KeyPath], password, dir: string,
  accountType: AccountType): AccountsResult[PublicAccount] =

  let
    accountInfos = ?self.accountsGenerator.storeDerivedAccounts(id, paths,
      password, dir).mapErrTo(StoreDerivedAcctsError)
    whisperAcct = ?(catch accountInfos[PATH_WHISPER]).mapErrTo(ChatAcctNotFound)
    alias = ?whisperAcct.publicKey.generateAlias.mapErrTo(
      GenerateAliasError)
    identicon = ?whisperAcct.publicKey.identicon.mapErrTo(
      GenerateIdenticonError)
    pubAccount = PublicAccount(
      creationTimestamp: getTime().toUnix,
      name: alias,
      identicon: identicon,
      keycardPairing: "",
      keyUid: keyUid # whisper key-uid
    )
  ?self.accountsDb.saveAccount(pubAccount).mapErrTo(SaveAccountsError)

  let
    defaultWalletAccountDerived = ?(catch accountInfos[PATH_DEFAULT_WALLET])
      .mapErrTo(DefWalletAcctNotFound)
    defaultWalletPubKey = ?SkPublicKey.fromHex(
      defaultWalletAccountDerived.publicKey).mapErrTo(InvalidPublicKey)
    whisperAccountPubKey = ?SkPublicKey.fromHex(whisperAcct.publicKey)
      .mapErrTo(InvalidPublicKey)
    defaultWalletAccount = accounts.Account(
      address: ?defaultWalletAccountDerived.address.parseAddress.mapErrTo(
        ParseAddressError),
      wallet: true.some,
      chat: false.some,
      `type`: some($accountType),
      storage: STORAGE_ON_DEVICE.some,
      path: PATH_DEFAULT_WALLET.some,
      publicKey: defaultWalletPubKey.some,
      name: "Status account".some,
      color: "#4360df".some
    )
    whisperAccount = accounts.Account(
      address: ?whisperAcct.address.parseAddress.mapErrTo(ParseAddressError),
      wallet: false.some,
      chat: true.some,
      `type`: some($accountType),
      storage: STORAGE_ON_DEVICE.some,
      path: PATH_WHISPER.some,
      publicKey: whisperAccountPubKey.some,
      name: pubAccount.name.some,
      color: "#4360df".some
    )

  # We need an inited user db to create accounts, which requires a login.
  # First, record if we are currently logged in, and then init the user db
  # if not. After we know the db has been inited, create the needed accounts.
  # Once finished, close the db if we were originally logged out.
  let wasLoggedIn = self.loginState == LoginState.loggedin
  if not wasLoggedIn:
    ?self.initUserDb(keyUid, password).mapErrTo(
      {DbError.KeyError: InvalidPassword}.toTable, InitUserDbError)
    self.setLoginState(LoginState.loggedin)

  let userDb = ?self.userDb.mapErrTo(UserDbError)
  ?userDb.createAccount(defaultWalletAccount).mapErrTo(CreateAcctError)
  ?userDb.createAccount(whisperAccount).mapErrTo(CreateAcctError)

  if not wasLoggedIn:
    ?self.closeUserDb.mapErrTo(CloseDbError)
    self.setLoginState(LoginState.loggedout)

  ok pubAccount

proc createAccount*(self: StatusObject, mnemonicPhraseLength: int,
  bip39Passphrase, password: string, dir: string):
  AccountsResult[PublicAccount] =

  if self.loginState != LoginState.loggedout:
    return err MustBeLoggedOut

  let
    n = 1 # hardcode only one account being created
    paths = @[PATH_WALLET_ROOT, PATH_EIP_1581, PATH_WHISPER, PATH_DEFAULT_WALLET]
    accounts = ?self.accountsGenerator.generateAndDeriveAddresses(
      mnemonicPhraseLength, n, bip39Passphrase, paths).mapErrTo(
      GenerateDeriveError)
    account = accounts[n - 1]

  ?self.initUserDb(account.keyUid, password).mapErrTo(
    {DbError.KeyError: InvalidPassword}.toTable, InitUserDbError)

  self.setLoginState(LoginState.loggedin)

  let
    pubAccount = ?self.storeDerivedAccounts(account.id, account.keyUid, paths,
      password, dir, AccountType.Generated).mapErrTo(StoreDerivedAcctsError)
    uuidResult = ?uuidGenerate().mapErrTo(GenerateUuidError)

  let
    whisperAcct = ?(catch account.derived[PATH_WHISPER]).mapErrTo(
      ChatAcctNotFound)
    eip1581Acct = ?(catch account.derived[PATH_EIP_1581]).mapErrTo(
      Eip1581AcctNotFound)
    defWalletAcct = ?(catch account.derived[PATH_DEFAULT_WALLET]).mapErrTo(
      DefWalletAcctNotFound)
    walletRootAcct = ?(catch account.derived[PATH_WALLET_ROOT]).mapErrTo(
      WalletRootAcctNotFound)
    settings = Settings(
      keyUid: account.keyUid,
      mnemonic: (string account.mnemonic).some,
      publicKey: whisperAcct.publicKey,
      name: pubAccount.name.some,
      userAddress: ?account.address.parseAddress.mapErrTo(ParseAddressError),
      eip1581Address: ?eip1581Acct.address.parseAddress.mapErrTo(
        ParseAddressError),
      dappsAddress: ?defWalletAcct.address.parseAddress.mapErrTo(
        ParseAddressError),
      walletRootAddress: (?walletRootAcct.address.parseAddress.mapErrTo(
        ParseAddressError)).some,
      previewPrivacy: true,
      signingPhrase: generateSigningPhrase(3),
      logLevel: "INFO".some, # TODO: how can we use the runtime LogLevel setting?
      latestDerivedPath: 0,
      networks: DEFAULT_NETWORKS,
      currency: "usd".some, # TODO: move to constants
      photoPath: pubAccount.identicon,
        # TODO: change photoPath to identicon
      wakuEnabled: true.some,
      walletVisibleTokens: (%* {
        "mainnet": ["SNT"]
      }).some,
      appearance: 0,
      currentNetwork: DEFAULT_NETWORK_NAME,
      installationID: $uuidResult
    )
    # TODO: a proper node config needs to
    # be created and stored on login (fleet info should be downloaded on login)
    nodeConfig =  ?(catchEx NODE_CONFIG.parseJson).mapErrTo(
      ParseNodeConfigError)

  let userDb = ?self.userDb.mapErrTo(UserDbError)
  ?userDb.createSettings(settings, nodeConfig).mapErrTo(CreateSettingsError)
  ?self.closeUserDb.mapErrTo(CloseDbError)
  self.setLoginState(LoginState.loggedout)

  ok pubAccount

proc getChatAccount*(self: StatusObject): AccountsResult[accounts.Account] =
  let
    userDb = ?self.userDb.mapErrTo(UserDbError)
    acct = ?userDb.getChatAccount.mapErrTo(GetChatAcctError)

  ok acct

proc getPublicAccounts*(self: StatusObject):
  AccountsResult[seq[PublicAccount]] =

  let accts = ?self.accountsDb.getPublicAccounts().mapErrTo(GetPublicAcctsError)
  ok accts

proc importMnemonic*(self: StatusObject, mnemonic: Mnemonic,
  bip39Passphrase, password, dir: string): AccountsResult[PublicAccount] =

  let
    imported = ?self.accountsGenerator.importMnemonic(mnemonic,
      bip39Passphrase).mapErrTo(ImportMnemonicFailure)
    paths = @[PATH_WALLET_ROOT, PATH_EIP_1581, PATH_WHISPER,
      PATH_DEFAULT_WALLET]
    pubAccount = ?self.storeDerivedAccounts(imported.id, imported.keyUid,
      paths, password, dir, AccountType.Seed).mapErrTo(StoreDerivedAcctsError)

  ok pubAccount

proc saveAccount*(self: StatusObject, account: PublicAccount):
  AccountsResult[PublicAccount] {.raises: [].} =

  ?self.accountsDb.saveAccount(account).mapErrTo(SaveAccountsError)
  ok account
