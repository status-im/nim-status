{.push raises: [Defect].}

import # std libs
  std/[options, sequtils, strformat, strutils, sugar, tables]

import # vendor libs
  eth/keyfile/uuid, secp256k1, web3/ethtypes

import # status modules
  ../private/accounts/[accounts, generator/generator],
  ../private/[conversions, settings],
  ../private/extkeys/[paths, types],
  ./auth, ./common

export
  accounts, common
# TODO: do we still need these exports?
# auth, conversions, paths, secp256k1, settings, types, uuid

type
  WalletAccount* = ref object
    address*: Address
    name*: string

  WalletError* = enum
    CreateWalletError       = "wallet: failed to create wallet account due to " &
                                "a database error"
    DeriveAcctsError        = "wallet: error deriving accounts"
    DerivedAcctNotFound     = "wallet: derived account for key path doesn't " &
                                "exist"
    DeleteFailure           = "wallet: failed to delete wallet account due " &
                                "to a database error"
    DeleteKeyFileFailure    = "wallet: failed to delete wallet keystore file"
    ImportMnemonicFailure   = "wallet: failed to import mnemonic"
    InvalidPassword         = "wallet: invalid password"
    InvalidPrivateKey       = "wallet: provided hex is not a valid private key"
    InvalidPublicKey        = "wallet: provided hex is not a valid public key"
    GetSettingError         = "wallet: error getting setting"
    GetWalletError          = "wallet: failed to get wallet account(s) due a " &
                                "database error"
    PathFormatError         = "wallet: error creating new derived key path"
    LoadAccountError        = "wallet: error loading account from keystore file"
    MustBeLoggedIn          = "wallet: operation not permitted, must be " &
                                "logged in"
    NameFormatError         = "wallet: error creating default wallet name"
    ParseAddressError       = "wallet: failed to parse address from given hex"
    PasswordValidationError = "wallet: error while validating password"
    PrivateKeyAddressError  = "wallet: error getting address from private key"
    RootAddressError        = "wallet: root wallet address is null"
    SaveSettingError        = "wallet: error saving setting"
    StoreKeyFileError       = "wallet: error storing key file"
    UserDbError             = "wallet: user db error, must be logged in"
    WontDelete              = "wallet: no wallets exist for given address, " &
                                "or you are attempting to delete the default " &
                                "Status wallet for this account"


  WalletResult*[T] = Result[T, WalletError]

proc storeWalletAccount(self: StatusObject, name: string, address: Address,
  publicKey: Option[SkPublicKey], accountType: AccountType,
  path: KeyPath): WalletResult[accounts.Account] =

  var walletName = name
  let userDb = ?self.userDb.mapErrTo(UserDbError)
  if walletName == "":
    let walletAccts {.used.} = ?userDb.getWalletAccounts().mapErrTo(
      GetWalletError)
    walletName = ?(catch fmt"Wallet account {walletAccts.len}").mapErrTo(
      NameFormatError)

  let
    walletAccount = accounts.Account(
      address: address,
      wallet: false.some, # NOTE: this *should* be true, however in status-go,
      # only the wallet root account is true, and there is a unique db
      # constraint enforcing only one account to have wallet = true
      chat: false.some,
      `type`: ($accountType).some,
      storage: STORAGE_ON_DEVICE.some,
      path: path.some,
      publicKey: publicKey,
      name: walletName.some,
      color: "#4360df".some # TODO: pass in colour
    )
  ?userDb.createAccount(walletAccount).mapErrTo(CreateWalletError)

  ok walletAccount

proc storeDerivedAccount(self: StatusObject, id: UUID, path: KeyPath, name,
  password, dir: string, accountType: AccountType):
  WalletResult[accounts.Account] =

  let
    accountInfos = ?self.accountsGenerator.storeDerivedAccounts(id, @[path],
      password, dir).mapErrTo(DeriveAcctsError)
    acct = ?(catch accountInfos[path]).mapErrTo(DerivedAcctNotFound)

  let
    publicKey = ?SkPublicKey.fromHex(acct.publicKey).mapErrTo(
      InvalidPublicKey)
    address = ?acct.address.parseAddress.mapErrTo(ParseAddressError)

  return self.storeWalletAccount(name, address, publicKey.some, accountType,
    path)

proc addWalletAccount*(self: StatusObject, name, password,
  dir: string): WalletResult[accounts.Account] =

  if not self.isLoggedIn:
    return err MustBeLoggedIn

  let
    userDb = ?self.userDb.mapErrTo(UserDbError)
    address = ?userDb.getSetting(string, SettingsCol.WalletRootAddress)
      .mapErrTo(GetSettingError)
  if address.isNone:
    return err RootAddressError

  let
    lastDerivedPathIdx =
      ?userDb.getSetting(int, SettingsCol.LatestDerivedPath, 0)
        .mapErrTo(GetSettingError)
    parsedAddress = ?address.get.parseAddress.mapErrTo(ParseAddressError)
    loadedAccount =
      ?self.accountsGenerator.loadAccount(parsedAddress, password, dir)
        .mapErrTo([(KeystoreDecodeError, InvalidPassword)].toTable,
        LoadAccountError)
    newIdx = lastDerivedPathIdx + 1
    path = ?(catch fmt"{PATH_WALLET_ROOT}/{newIdx}").mapErrTo(PathFormatError)
    walletAccount = ?self.storeDerivedAccount(loadedAccount.id, KeyPath path,
      name, password, dir, AccountType.Generated)

  ?userDb.saveSetting(SettingsCol.LatestDerivedPath, newIdx).mapErrTo(
    SaveSettingError)

  ok walletAccount

proc storeImportedWalletAccount(self: StatusObject, privateKey: SkSecretKey,
  name, password, dir: string, accountType: AccountType):
  WalletResult[accounts.Account] =

  let isPasswordValid = ?self.validatePassword(password, dir).mapErrTo(
    PasswordValidationError)
  if not isPasswordValid:
    return err InvalidPassword

  discard ?self.accountsGenerator.storeKeyFile(privateKey, password, dir)
    .mapErrTo(StoreKeyFileError)

  let
    path = PATH_DEFAULT_WALLET # NOTE: this is the keypath
      # given to imported wallet accounts in status-desktop
    publicKey = privateKey.toPublicKey.some
    address = ?privateKey.toAddress.mapErrTo(PrivateKeyAddressError)

  return self.storeWalletAccount(name, address, publicKey, accountType, path)

proc addWalletPrivateKey*(self: StatusObject, privateKeyHex: string,
  name, password, dir: string): WalletResult[accounts.Account] =

  var privateKeyStripped = privateKeyHex
  privateKeyStripped.removePrefix("0x")

  let secretKey = ?SkSecretKey.fromHex(privateKeyStripped).mapErrTo(
    InvalidPrivateKey)

  return self.storeImportedWalletAccount(secretKey, name, password, dir,
    AccountType.Key)

proc addWalletSeed*(self: StatusObject, mnemonic: Mnemonic, name, password,
  dir, bip39Passphrase: string): WalletResult[accounts.Account] =

  let isPasswordValid = ?self.validatePassword(password, dir).mapErrTo(
    PasswordValidationError)
  if not isPasswordValid:
    return err InvalidPassword

  let imported = ?self.accountsGenerator.importMnemonic(mnemonic,
    bip39Passphrase).mapErrTo(ImportMnemonicFailure)

  return self.storeDerivedAccount(imported.id, PATH_DEFAULT_WALLET, name,
    password, dir, AccountType.Seed)

proc addWalletWatchOnly*(self: StatusObject, address: Address,
  name: string): WalletResult[accounts.Account] =

  return self.storeWalletAccount(name, address, SkPublicKey.none,
    AccountType.Watch, PATH_DEFAULT_WALLET)

proc deleteWalletAccount*(self: StatusObject, address: Address,
  password, dir: string): WalletResult[accounts.Account] =

  let isPasswordValid = ?self.validatePassword(password, dir).mapErrTo(
    PasswordValidationError)
  if not isPasswordValid:
    return err InvalidPassword

  let
    userDb = ?self.userDb.mapErrTo(UserDbError)
    deleted = ?userDb.deleteWalletAccount(address).mapErrTo(DeleteFailure)
  if deleted.isNone:
    return err WontDelete

  ?self.accountsGenerator.deleteKeyFile(address, password, dir).mapErrTo(
    DeleteKeyFileFailure)

  ok deleted.get


proc toWalletAccount(account: accounts.Account): WalletAccount {.used.} =
  let name = if account.name.isNone: "" else: account.name.get
  WalletAccount(address: account.address, name: name)

proc getWalletAccounts*(self: StatusObject): WalletResult[seq[WalletAccount]] =

  if not self.isLoggedIn:
    return err MustBeLoggedIn

  let
    userDb = ?self.userDb.mapErrTo(UserDbError)
    walletAccts = ?userDb.getWalletAccounts.mapErrTo(GetWalletError)
    accounts = walletAccts.map(a => a.toWalletAccount)
  ok accounts
