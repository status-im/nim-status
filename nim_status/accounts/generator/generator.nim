import # std libs
  std/[json, os, strformat, strutils, sugar, tables, times]

import # vendor libs
  eth/keys, eth/keyfile/[keyfile, uuid], json_serialization, secp256k1,
  stew/results, web3/ethtypes

import # nim-status libs
  ./account, ../../conversions, ../../extkeys/[hdkey, mnemonic, types],
  ../public_accounts, ./utils

export utils

type
  Generator* = ref object
    accounts*: TableRef[string, Account] # TODO: this should be made private,
      # and we should adjust tests accordingly. The tests should reflect client
      # usage, which should not obtain access to the accounts field.

  AccountResult = Result[Account, string]

  AddAccountResult = Result[UUID, string]

  DeriveAddressesResult = Result[Table[KeyPath, AccountInfo], string]

  DeriveChildAccountResult = Result[Account, string]

  DeriveChildAccountsResult = Result[Table[KeyPath, Account], string]

  FindKeyFileResult = Result[seq[(PathComponent, string)], string]

  GenerateAndDeriveAddressesResult* = Result[
    seq[GeneratedAndDerivedAccountInfo], string]

  GenerateResult = Result[seq[GeneratedAccountInfo], string]

  ImportMnemonicResult* = Result[GeneratedAccountInfo, string]

  ImportPrivateKeyResult* = Result[IdentifiedAccountInfo, string]

  LoadAccountResult* = Result[IdentifiedAccountInfo, string]

  StoreDerivedAccountsResult* = Result[Table[KeyPath, AccountInfo], string]

  StoreKeyFileResult* = Result[string, string]

proc new*(T: type Generator): T =
  T(accounts: newTable[string, Account]())

proc addAccount(self: Generator, acc: Account): AddAccountResult =
  let uuidResult = uuidGenerate()
  if uuidResult.isErr:
    return AddAccountResult.err "Error generating uuid: " & $uuidResult.error
  
  let uuid = uuidResult.get
  self.accounts[$uuid] = acc
  AddAccountResult.ok(uuid)

proc deriveChildAccount(self: Generator, a: Account,
  path: KeyPath): DeriveChildAccountResult =

  let
    childExtKey = ?a.extendedKey.derive(path)
    secretKey = childExtKey.secretKey
    account = Account(secretKey: secretKey, extendedKey: childExtKey)

  ok(account)

proc deriveChildAccounts(self: Generator, a: Account,
  paths: seq[KeyPath]): DeriveChildAccountsResult =

  var derived = initTable[KeyPath, Account]()
  for path in paths:
    derived[path] = ?self.deriveChildAccount(a, path)

  DeriveChildAccountsResult.ok(derived)

proc findAccount(self: Generator, accountId: UUID): AccountResult =
  let id = $accountId
  if not self.accounts.hasKey(id):
    return AccountResult.err "Account doesn't exist"

  AccountResult.ok(self.accounts[id])

proc deriveAddresses*(self: Generator, accountId: UUID,
  paths: seq[KeyPath]): DeriveAddressesResult =
  
  let
    acc = ?self.findAccount(accountId)
    children = ?self.deriveChildAccounts(acc, paths)

  var derived = initTable[KeyPath, AccountInfo]()

  for path, account in children.pairs:
    derived[path] = account.toAccountInfo()

  DeriveAddressesResult.ok(derived)

proc importMnemonic*(self: Generator, mnemonic: Mnemonic,
  bip39Passphrase: string): ImportMnemonicResult =

  let
    seed = mnemonic.mnemonicSeed(bip39Passphrase)
    masterExtKey = ?seed.newMaster()
    account = Account(secretKey: masterExtKey.secretKey,
      extendedKey: masterExtKey)
    id = ?self.addAccount(account)
    generatedAccInfo = account.toGeneratedAccountInfo(id, mnemonic)

  ImportMnemonicResult.ok(generatedAccInfo)

proc importPrivateKey*(self: Generator,
  privateKeyHex: string): ImportPrivateKeyResult =

  var privateKeyStripped = privateKeyHex
  privateKeyStripped.removePrefix("0x")

  let secretKeyResult = SkSecretKey.fromHex(privateKeyStripped)
  if secretKeyResult.isErr:
    return ImportPrivateKeyResult.err $secretKeyResult.error

  let
    secretKey = secretKeyResult.get
    extPrivKey = ExtendedPrivKey(secretKey: secretKey)
    account = Account(secretKey: secretKey, extendedKey: extPrivKey)
    id = ?self.addAccount(account)

  ImportPrivateKeyResult.ok account.toIdentifiedAccountInfo(id)

proc generate*(self: Generator, mnemonicPhraseLength: int, n: int,
  bip39Passphrase: string): GenerateResult =

  var generated: seq[GeneratedAccountInfo] = @[]

  for i in 0..n-1:
    let entropyStrength = mnemonicPhraseLengthToEntropyStrength(mnemonicPhraseLength)
    let phrase = mnemonicPhrase(entropyStrength, Language.English)
    generated.add ?self.importMnemonic(phrase, bip39Passphrase)

  GenerateResult.ok(generated)

proc generateAndDeriveAddresses*(self: Generator, mnemonicPhraseLength: int,
  n: int, bip39Passphrase: string,
  paths: seq[KeyPath]): GenerateAndDeriveAddressesResult =

  let masterAccounts = ?self.generate(mnemonicPhraseLength, n, bip39Passphrase)

  var generatedAndDerived: seq[GeneratedAndDerivedAccountInfo] = @[]

  for i in 0..masterAccounts.len - 1:
    let
      generatedAccountInfo = masterAccounts[i]
      derived = ?self.deriveAddresses(generatedAccountInfo.id, paths)

    generatedAndDerived.add generatedAccountInfo.toGeneratedAndDerived(derived)
  
  GenerateAndDeriveAddressesResult.ok(generatedAndDerived)

proc findKeyFile(self: Generator, address: Address,
  dir: string): FindKeyFileResult =

  let strAddress = $address

  var found: seq[(PathComponent, string)] = @[]
  for kind, path in dir.walkDir:
    if kind == PathComponent.pcFile and path.endsWith(strAddress.strip0xPrefix):
      found.add (kind, path)

  if found.len == 0:
    return FindKeyFileResult.err "Could not find key file for address " &
      strAddress
  if found.len > 1:
    return FindKeyFileResult.err "Found more than one key file for address " &
      strAddress

  FindKeyFileResult.ok found

proc loadAccount*(self: Generator, address: Address, password: string,
  dir: string = ""): LoadAccountResult =

  let
    found = ?self.findKeyFile(address, dir)
    (kind, path) = found[0]
    json = parseFile(path)
    privateKeyResult = decodeKeyFileJson(json, password)

  if privateKeyResult.isErr:
    return LoadAccountResult.err fmt"Error decoding private key from file. Wrong password?"

  # TODO: Add ValidateKeystoreExtendedKey
  # https://github.com/status-im/status-go/blob/e0eb96a992fea9d52d16ae9413b1198827360278/accounts/generator/generator.go#L213-L215

  let
    secretKey = SkSecretKey(privateKeyResult.get)
    extendedKey = ?secretKey.toExtendedKey()
    account = Account(secretKey: secretKey, extendedKey: extendedKey)
    id = ?self.addAccount(account)
    identifiedAccInfo = account.toIdentifiedAccountInfo(id)

  LoadAccountResult.ok(identifiedAccInfo)

proc reset(self: Generator) =
  # Reset resets the accounts map removing all the accounts from memory.
  self.accounts.clear()

proc storeKeyFile*(self: Generator, secretKey: SkSecretKey, password: string,
  dir: string, version: int = 3, cryptkind: CryptKind = AES128CTR,
  kdfkind: KdfKind = PBKDF2, workfactor: int = 0): StoreKeyFileResult =

  let
    address = secretKey.toAddress
    findKeyFileResult = self.findKeyFile(address, dir)

  if findKeyFileResult.isOk:
    return StoreKeyFileResult.err fmt"Key file for address {address} already " &
      "exists"

  var workfactorFinal = workfactor
  when not defined(release):
    # reduce the account creation time by a factor of 5 for debug builds only
    if workfactorFinal == 0: workfactorFinal = 100

  let keyFileJsonResult = createKeyFileJson(PrivateKey secretKey, password,
    version, cryptkind, kdfkind, workfactorFinal)

  if keyFileJsonResult.isErr:
    return StoreKeyFileResult.err "Error creating key file: " &
      $keyFileJsonResult.error

  let
    keyFileJson = $keyFileJsonResult.get
    now {.used.} = now().format("yyyy-MM-dd'T'HH-mm-ss'.'fffffffff'Z'")
    keyFilePath = dir / fmt"UTC--{now}--{($address).strip0xPrefix}"

  dir.createDir()
  keyFilePath.writeFile(keyFileJson)
  self.reset()
  StoreKeyFileResult.ok keyFilePath

proc storeDerivedAccounts*(self: Generator, accountId: UUID, paths: seq[KeyPath],
  password: string, dir: string = "", version: int = 3,
  cryptkind: CryptKind = AES128CTR, kdfkind: KdfKind = PBKDF2,
  workfactor: int = 0): StoreDerivedAccountsResult =

  let
    acc = ?self.findAccount(accountId)
    derived = ?self.deriveChildAccounts(acc, paths)

  var accounts = initTable[KeyPath, AccountInfo]()

  for path, account in derived.pairs:
    let accountInfo = account.toAccountInfo

    discard ?self.storeKeyFile(account.secretKey, password, dir,
      version, cryptkind, kdfkind, workfactor)

    accounts[path] = accountInfo

  StoreDerivedAccountsResult.ok(accounts)
