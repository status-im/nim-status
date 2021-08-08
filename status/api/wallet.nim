{.push raises: [Defect].}

import # std libs
  std/[options, sequtils, strformat, strutils, sugar, tables]

import # vendor libs
  eth/keyfile/uuid, secp256k1, web3/ethtypes

import # status modules
  ../private/[accounts/accounts, conversions, settings],
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

  WalletAccountResult* = Result[accounts.Account, string]

  WalletAccountsResult* = Result[seq[WalletAccount], string]

proc storeWalletAccount(self: StatusObject, name: string, address: Address,
  publicKey: Option[SkPublicKey], accountType: AccountType,
  path: KeyPath): WalletAccountResult =

  const errorMsg = "Error storing wallet accounts: "

  try:

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
        storage: STORAGE_ON_DEVICE.some,
        path: path.some,
        publicKey: publicKey,
        name: walletName.some,
        color: "#4360df".some # TODO: pass in colour
      )
    self.userDb.createAccount(walletAccount)

    return WalletAccountResult.ok(walletAccount)

  except AccountDbError as e:
    return WalletAccountResult.err errorMsg & e.msg
  except StatusApiError as e:
    return WalletAccountResult.err errorMsg & e.msg
  except ValueError as e:
    return WalletAccountResult.err errorMsg & e.msg

proc storeDerivedAccount(self: StatusObject, id: UUID, path: KeyPath, name,
  password, dir: string, accountType: AccountType): WalletAccountResult =

  let
    accountInfos = ?self.accountsGenerator.storeDerivedAccounts(id, @[path],
      password, dir)
    acct = try: accountInfos[path]
           except KeyError as e: return WalletAccountResult.err "Error " &
             "getting derived account: " & e.msg

  let walletPubKeyResult = SkPublicKey.fromHex(acct.publicKey)

  if walletPubKeyResult.isErr:
    return WalletAccountResult.err $walletPubKeyResult.error

  let
    address = try: acct.address.parseAddress
              except ValueError as e: return WalletAccountResult.err "Error " &
                "parsing address: " & e.msg
    publicKey = walletPubKeyResult.get.some

  return self.storeWalletAccount(name, address, publicKey, accountType, path)

proc addWalletAccount*(self: StatusObject, name, password,
  dir: string): WalletAccountResult =

  if not self.isLoggedIn:
    return WalletAccountResult.err "Not logged in. You must be logged in to " &
      "create a new wallet account."

  const
    errorMsgSetting = "Error getting setting: "
    errorMsgParse = "Error parsing root wallet address: "
  try:
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

    return WalletAccountResult.ok(walletAccount)
  except SettingDbError as e:
    return WalletAccountResult.err errorMsgSetting & e.msg
  except StatusApiError as e:
    return WalletAccountResult.err errorMsgSetting & e.msg
  except UnpackError as e:
    return WalletAccountResult.err errorMsgSetting & e.msg
  except ValueError as e:
    return WalletAccountResult.err errorMsgParse & e.msg

proc storeImportedWalletAccount(self: StatusObject, privateKey: SkSecretKey,
  name, password, dir: string, accountType: AccountType): WalletAccountResult
  {.raises: [].} =

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

proc addWalletPrivateKey*(self: StatusObject, privateKeyHex: string,
  name, password, dir: string): WalletAccountResult {.raises: [].} =

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
  dir, bip39Passphrase: string): WalletAccountResult {.raises: [].} =

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
  name: string): WalletAccountResult {.raises: [].} =

  try:
    return self.storeWalletAccount(name, address, SkPublicKey.none,
      AccountType.Watch, PATH_DEFAULT_WALLET)

  except Exception as e:
    return WalletAccountResult.err e.msg

proc deleteWalletAccount*(self: StatusObject, address: Address,
  password, dir: string): WalletAccountResult {.raises: [].} =

  try:
    if not self.validatePassword(password, dir):
      return WalletAccountResult.err "Invalid password"

    let deleted = self.userDb.deleteWalletAccount(address)
    if deleted.isNone:
      return WalletAccountResult.err fmt"No wallet exists for {address}, " &
        "or you are attempting to delete the default Status wallet for this " &
        "account."

    ?self.accountsGenerator.deleteKeyFile(address, password, dir)

    return WalletAccountResult.ok deleted.get

  except Exception as e:
    return WalletAccountResult.err e.msg


proc toWalletAccount(account: accounts.Account): WalletAccount {.used.} =
  let name = if account.name.isNone: "" else: account.name.get
  WalletAccount(address: account.address, name: name)

proc getWalletAccounts*(self: StatusObject): WalletAccountsResult
  {.raises: [].} =

  if not self.isLoggedIn:
    return WalletAccountsResult.err "Not logged in. Must be logged in to get " &
      "wallet accounts."
  try:
    let accounts = self.userDb.getWalletAccounts().map(a => a.toWalletAccount)
    return WalletAccountsResult.ok accounts
  except Exception as e:
    return WalletAccountsResult.err "Error getting wallet accounts: " & e.msg
