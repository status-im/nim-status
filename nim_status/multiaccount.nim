import # std libs
  std/[json, os, strutils]

import # vendor libs
  chronicles, eth/[keys, keyfile], nimcrypto/[sha2, pbkdf2, hash, hmac],
  secp256k1, stew/[results, byteutils]

import # nim-status libs
  ./mnemonic, ./account, ./account/types


const
    PATH_WALLET_ROOT* = "m/44'/60'/0'/0"
    PATH_EIP_1581* = "m/43'/60'/1581'"
      # EIP1581 Root Key, the extended key from which any whisper key/encryption
      # key can be derived
    PATH_DEFAULT_WALLET* = PATH_WALLET_ROOT & "/0"
      # BIP44-0 Wallet key, the default wallet key
    PATH_WHISPER* = PATH_EIP_1581 & "/0'/0"
      # EIP1581 Chat Key 0, the default whisper key

type MultiAccount* = object
  mnemonic*: string
  accounts*: seq[Account]

export KeySeed, Mnemonic, SecretKeyResult, KeyPath

# MnemonicPhraseLengthToEntropyStrength returns the entropy strength for a given mnemonic length
proc mnemonicPhraseLengthToEntropyStrength*(length: int): int =
  if length < 12 or length > 24 or length mod 3 != 0:
    return 0

  let bitsLength = length * 11
  let checksumLength = bitsLength mod 32

  return bitsLength - checksumLength

proc toKeyUid(publicKey: PublicKey): string =
  let hash = sha256.digest(publicKey.toRaw())
  "0x" & toHex(toOpenArray(hash.data, 0, len(hash.data) - 1))

proc buildAccount(privateKey: PrivateKey): Account =
  var acc = Account()
  acc.privateKey = $privateKey
  let publicKey = privateKey.toPublicKey()
  acc.publicKey = "0x04" & $publicKey
  acc.address = publicKey.toAddress()
  acc.keyUid = publicKey.toKeyUid()

  return acc

proc generateAndDeriveAddresses*(mnemonicPhraseLength: int, n: int,
  bip39Passphrase: string, paths: seq[string]): seq[MultiAccount] =

  let entropyStrength = mnemonicPhraseLengthToEntropyStrength(mnemonicPhraseLength)
  var multiAccounts = newSeq[MultiAccount]()
  for i in 0..<n:
    let phrase = mnemonicPhrase(entropyStrength, Language.English)
    let keySeed = getSeed(Mnemonic phrase, bip39Passphrase)
    var multiAcc: MultiAccount
    multiAcc.mnemonic = phrase
    multiAcc.accounts = newSeq[Account]()
    for p in paths:
      let skResult = derive(keySeed, KeyPath p)
      var acc = buildAccount(cast[PrivateKey](skResult.get()))
      acc.path = p
      multiAcc.accounts.add(acc)

    multiAccounts.add(multiAcc)

  return multiAccounts

proc storeDerivedAccounts*(multiAcc: MultiAccount, password: string,
  dir: string = "", version: int = 3, cryptkind: CryptKind = AES128CTR,
  kdfkind: KdfKind = PBKDF2, workfactor: int = 0) =

  var workfactorFinal = workfactor
  when not defined(release):
    # reduce the account creation time by a factor of 5 for debug builds only
    if workfactorFinal == 0: workfactorFinal = 100

  for acc in multiAcc.accounts:
    let privateKey = acc.privateKey
    let keyFileJson = createKeyFileJson(PrivateKey.fromHex(privateKey).get(), password, version, cryptkind, kdfkind, workfactorFinal)

    writeFile(dir / acc.address, $keyFileJson.get())


proc loadAccount*(address: string, password: string, dir: string = ""): Account =
  let json = parseFile(dir / address)
  let privateKey = decodeKeyFileJson(json, password)

  return buildAccount(privateKey.get())
