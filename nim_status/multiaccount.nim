import # std libs
  times,
  std/[json, os, parseutils, streams, strutils]

import # vendor libs
  chronicles,
  eth/[keys, keyfile],
  nimcrypto/[sha2, pbkdf2, hash, hmac],
  normalize, secp256k1,
  stew/[results, byteutils]

import # nim-status libs
  ./account, ./account/paths, ./account/types, ./mnemonic

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

proc buildAccount(privateKey: PrivateKey): Account =
  var acc = Account()
  acc.privateKey = $privateKey
  let publicKey = privateKey.toPublicKey()
  acc.publicKey = $publicKey
  acc.address = PublicKey(publicKey).toAddress()

  return acc

proc generateAndDeriveAddresses*(mnemonicPhraseLength: int, n: int, bip39Passphrase: string, paths: seq[string]): seq[MultiAccount] =

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

proc storeDerivedAccounts*(multiAcc: MultiAccount, password: string, dir: string = "", pathStrings: seq[string] = newSeq[string](), workFactor: int = 0) =
  for acc in multiAcc.accounts:
    let privateKey = acc.privateKey
    var tCreateKeyFileJson = cpuTime()
    let keyFileJson = createKeyFileJson(PrivateKey.fromHex(privateKey).get(),
      password, 3, CryptKind.AES128CTR, KdfKind.PBKDF2, workfactor)
    debug "PROFILE nim_status/multiaccount, createKeyFileJson", time=cpuTime()-tCreateKeyFileJson, acc

    writeFile(dir / acc.address, $keyFileJson.get())


proc loadAccount*(address: string, password: string, dir: string = ""): Account =
  let json = parseFile(dir / address)
  let privateKey = decodeKeyFileJson(json, password)

  return buildAccount(privateKey.get())
