{.push raises: [Defect].}

import # std libs
  std/[json, os, strformat, strutils, tables, times]

import # vendor libs
  eth/keys,
  eth/keyfile/[keyfile, uuid],
  json_serialization, secp256k1, web3/ethtypes

import # status modules
  ../../common, ../../conversions, ../../util,
  ../../extkeys/[hdkey, mnemonic, types],
  ./account, ./utils

export utils

type
  Generator* = ref object
    accounts*: TableRef[string, Account] # TODO: this should be made private,
      # and we should adjust tests accordingly. The tests should reflect client
      # usage, which should not obtain access to the accounts field.

  GeneratorError* = enum
    AccountNotLoaded        = "gen: account cannot be found because it is " &
                                "not loaded"
    UuidGenerateError       = "gen: error generating UUID for account"
    KeystoreSearchError     = "gen: error searching directory for keystore file"
    KeystoreNotFound        = "gen: could not find keystore file for address"
    MultipleKeystoresFound  = "gen: found more than one key file for address"
    KeystoreJsonParseError  = "gen: error parsing keystore file in to JSON"
    KeystoreDecodeError     = "gen: error decoding keystore file, wrong " &
                                "password?"
    KeystoreDeleteFailure   = "gen: error deleting keystore file"
    KeystoreExists          = "gen: keystore file already exists"
    KeystoreCreateFailure   = "gen: error creating keystore file"
    DerivationFailure       = "gen: failed to derive an extended key from " &
                                "key path"
    CreateMasterKeyFailure  = "gen: failed to create new master from seed, " &
                                "invalid seed"
    InvalidPrivateKey       = "gen: invalid private key"
    PrivKeyToAddressFailure = "gen: failed to parse address (Priv Key -> Pub " &
                                "Key -> hex)"
    CreateMnemonicFailure   = "gen: failed to create mnemoic given entropy " &
                                "strength"
    KeystoreFilenameError   = "gen: error creating keystore file name"

  GeneratorResult*[T] = Result[T, GeneratorError]

proc new*(T: type Generator): T {.raises: [].} =
  T(accounts: newTable[string, Account]())

proc addAccount(self: Generator, acc: Account): GeneratorResult[UUID] =
  let uuid = ?uuidGenerate().mapErrTo(UuidGenerateError)
  self.accounts[$uuid] = acc
  ok uuid

proc deriveChildAccount(self: Generator, a: Account,
  path: KeyPath): GeneratorResult[Account] {.used.} =

  let
    childExtKey = ?a.extendedKey.derive(path).mapErrTo(DerivationFailure)
    secretKey = childExtKey.secretKey
    account = Account(secretKey: secretKey, extendedKey: childExtKey)

  ok account

proc deriveChildAccounts(self: Generator, a: Account,
  paths: seq[KeyPath]): GeneratorResult[Table[KeyPath, Account]] =

  var derived = initTable[KeyPath, Account]()
  for path in paths:
    derived[path] = ?self.deriveChildAccount(a, path)

  ok derived

proc findAccount*(self: Generator, accountId: UUID): GeneratorResult[Account] =
  let id = $accountId
  if not self.accounts.hasKey(id):
    return err AccountNotLoaded
  try:
    ok self.accounts[id]
  except KeyError:
    err AccountNotLoaded

proc deriveAddresses*(self: Generator, accountId: UUID, paths: seq[KeyPath]):
  GeneratorResult[Table[KeyPath, AccountInfo]] =

  let
    acc = ?self.findAccount(accountId)
    children = ?self.deriveChildAccounts(acc, paths)

  var derived = initTable[KeyPath, AccountInfo]()

  for path, account in children.pairs:
    derived[path] = account.toAccountInfo()

  ok derived

proc importMnemonic*(self: Generator, mnemonic: Mnemonic,
  bip39Passphrase: string): GeneratorResult[GeneratedAccountInfo] =

  let
    seed = mnemonic.mnemonicSeed(bip39Passphrase)
    masterExtKey = ?seed.newMaster().mapErrTo(CreateMasterKeyFailure)
    account = Account(secretKey: masterExtKey.secretKey,
      extendedKey: masterExtKey)
    id = ?self.addAccount(account)
    generatedAccInfo = account.toGeneratedAccountInfo(id, mnemonic)

  ok generatedAccInfo

proc importPrivateKey*(self: Generator, privateKeyHex: string):
  GeneratorResult[IdentifiedAccountInfo] =

  let
    privateKeyStripped = privateKeyHex.strip0xPrefix
    secretKey = ? SkSecretKey.fromHex(privateKeyStripped).mapErrTo(
      InvalidPrivateKey)
    extPrivKey = ExtendedPrivKey(secretKey: secretKey)
    account = Account(secretKey: secretKey, extendedKey: extPrivKey)
    id = ?self.addAccount(account)

  ok account.toIdentifiedAccountInfo(id)

proc generate*(self: Generator, mnemonicPhraseLength: int, n: int,
  bip39Passphrase: string): GeneratorResult[seq[GeneratedAccountInfo]] =

  var generated: seq[GeneratedAccountInfo] = @[]

  for i in 0..n-1:
    let
      entropyStrength = mnemonicPhraseLengthToEntropyStrength(
        mnemonicPhraseLength)
      phrase = ? mnemonicPhrase(entropyStrength, Language.English).mapErrTo(
        CreateMnemonicFailure)
    generated.add ?self.importMnemonic(phrase, bip39Passphrase)

  ok generated

proc generateAndDeriveAddresses*(self: Generator, mnemonicPhraseLength: int,
  n: int, bip39Passphrase: string,
  paths: seq[KeyPath]): GeneratorResult[seq[GeneratedAndDerivedAccountInfo]] =

  let masterAccounts = ?self.generate(mnemonicPhraseLength, n, bip39Passphrase)

  var generatedAndDerived: seq[GeneratedAndDerivedAccountInfo] = @[]

  for i in 0..masterAccounts.len - 1:
    let
      generatedAccountInfo = masterAccounts[i]
      derived = ?self.deriveAddresses(generatedAccountInfo.id, paths)

    generatedAndDerived.add generatedAccountInfo.toGeneratedAndDerived(derived)

  ok generatedAndDerived

proc findKeyFile(self: Generator, address: Address,
  dir: string): GeneratorResult[string] =

  let strAddress = $address

  var found: seq[(PathComponent, string)] = @[]
  try:
    for kind, path in dir.walkDir:
      if kind == PathComponent.pcFile and path.endsWith(strAddress.strip0xPrefix):
        found.add (kind, path)
  except OSError:
    return err KeystoreSearchError

  if found.len == 0: return err KeystoreNotFound
  if found.len > 1: return err MultipleKeystoresFound

  let (_, path) = found[0]
  ok path

proc deleteKeyFile*(self: Generator, address: Address, password: string,
  dir: string): GeneratorResult[void] =

  let
    path = ?self.findKeyFile(address, dir)
    json = ?(catchEx parseFile(path)).mapErrTo(KeystoreJsonParseError)

  discard ?decodeKeyFileJson(json, password).mapErrTo(KeystoreDecodeError)

  try: path.removeFile()
  except OSError: return err KeystoreDeleteFailure

  ok()

proc loadAccount*(self: Generator, address: Address, password: string,
  dir: string = ""): GeneratorResult[IdentifiedAccountInfo] =

  let
    path = ?self.findKeyFile(address, dir)
    json =  ?(catchEx parseFile(path)).mapErrTo(KeystoreJsonParseError)
    privateKey = ?decodeKeyFileJson(json, password).mapErrTo(
      KeystoreDecodeError)

  # TODO: Add ValidateKeystoreExtendedKey
  # https://github.com/status-im/status-go/blob/e0eb96a992fea9d52d16ae9413b1198827360278/accounts/generator/generator.go#L213-L215

  let
    secretKey = SkSecretKey(privateKey)
    extendedKey = secretKey.toExtendedKey()
    account = Account(secretKey: secretKey, extendedKey: extendedKey)
    id = ?self.addAccount(account)
    identifiedAccInfo = account.toIdentifiedAccountInfo(id)

  ok identifiedAccInfo

proc reset(self: Generator) {.raises: [].} =
  # Reset resets the accounts map removing all the accounts from memory.
  self.accounts.clear()

proc storeKeyFile*(self: Generator, secretKey: SkSecretKey, password: string,
  dir: string, version: int = 3, cryptkind: CryptKind = AES128CTR,
  kdfkind: KdfKind = PBKDF2, workfactor: int = 0): GeneratorResult[string] =

  let address = ?secretKey.toAddress.mapErrTo(PrivKeyToAddressFailure)
  if self.findKeyFile(address, dir).isOk: return err KeystoreExists

  var workfactorFinal = workfactor
  when not defined(release):
    # reduce the account creation time by a factor of 5 for debug builds only
    if workfactorFinal == 0: workfactorFinal = 100

  let
    keyFileJson = $ ? createKeyFileJson(PrivateKey secretKey, password,
      version, cryptkind, kdfkind, workfactorFinal).mapErrTo(
        KeystoreCreateFailure)
    now {.used.} = now().utc.format("yyyy-MM-dd'T'HH-mm-ss'.'fffffffff'Z'")
    filenameResult = catch: fmt"UTC--{now}--{($address).strip0xPrefix}"
    filename = ? filenameResult.mapErrTo(KeystoreFilenameError)
    keyFilePath = dir / filename

  try:
    createDir(dir)
    keyFilePath.writeFile(keyFileJson)
  except IOError, OSError:
    return err KeystoreCreateFailure

  self.reset()
  ok keyFilePath

proc storeDerivedAccounts*(self: Generator, accountId: UUID, paths: seq[KeyPath],
  password: string, dir: string = "", version: int = 3,
  cryptkind: CryptKind = AES128CTR, kdfkind: KdfKind = PBKDF2,
  workfactor: int = 0): GeneratorResult[Table[KeyPath, AccountInfo]] =

  let
    acc = ?self.findAccount(accountId)
    derived = ?self.deriveChildAccounts(acc, paths)

  var accounts = initTable[KeyPath, AccountInfo]()

  for path, account in derived.pairs:
    let accountInfo = account.toAccountInfo

    discard ?self.storeKeyFile(account.secretKey, password, dir,
      version, cryptkind, kdfkind, workfactor)

    accounts[path] = accountInfo

  ok accounts
