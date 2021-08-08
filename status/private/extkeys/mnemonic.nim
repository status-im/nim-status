{.push raises: [Defect].}

import # std libs
  std/[os, parseutils, sequtils, strutils]

import # vendor libs
  nimcrypto/[pbkdf2, sha2, sysrand],
  normalize

import # status modules
  ../common, ./types

export types

type
  EntropyStrength* = distinct uint
  BitSeq = seq[byte]
  Language* = enum
    English, French, Italian, Japanese
  MnemonicError* = object of StatusError

proc `$`*(s: BitSeq): string {.raises: [].} =
  var str: string
  for b in s:
    str.add(if b == 1: '1' else: '0')

  return str

proc getBits*(b: byte): BitSeq {.raises: [].} =
  var s = newSeq[byte]()
  for i in 0..7:
    let bit = (b shr i) and 1
    s.insert(bit, 0)

  return s

proc getBits*(byteSeq: seq[byte]): BitSeq {.raises: [].} =
  var s: BitSeq
  for b in byteSeq:
    s = concat(s, getBits(b))

  return s

proc getBits*(byteStr: string): BitSeq {.raises: [].} =
  var s: BitSeq
  for b in byteStr:
    let bits = getBits(b.byte)
    s = concat(s, bits)

  return s

# MnemonicPhrase returns a human readable seed for BIP32 Hierarchical Deterministic Wallets
proc mnemonicPhrase*(strength: EntropyStrength, language: Language): Mnemonic
  {.raises: [MnemonicError].} =
  # The mnemonic must encode entropy in a multiple of 32 bits.
  # With more entropy security is improved but the sentence length increases.
  # We refer to the initial entropy length as ENT. The recommended size of ENT is 128-256 bits.

  if strength.int mod 32 > 0 or strength.int < 128 or strength.int > 256:
    raise (ref MnemonicError)(msg: "Error generating mnemonic: invalid " &
      "entropy strength")

  # First, an initial entropy of ENT bits is generated
  var entropy = newSeq[byte](strength.int div 8)
  discard sysrand.randomBytes(addr entropy[0], strength.int div 8)
  var entropyBits = getBits(entropy)


  # A checksum is generated by taking the first bits of its SHA256 hash ( ENT / 32 )
  # This checksum is appended to the end of the initial entropy.
  let hash = sha256.digest(entropy)
  # let checksumBitLength = strength.int div 32
  let checksum = getBits($hash)

  entropyBits = concat(entropyBits, checksum[0..3])

  # TODO: does "../wordlists" work on windows?
  const wordlist = staticRead("../wordlists" / "english.txt")
  let wordSeq = wordlist.split("\n")

  let wordBitSeq = entropyBits.distribute(12)
  var words = newSeq[string]()
  for w in wordBitSeq:
    var n: uint16
    discard parseBin($w, n)
    words.add(wordSeq[n])

  var wordSeparator = " "

  if language == Language.Japanese:
    wordSeparator = "　"


  return Mnemonic words.join(wordSeparator)

proc mnemonicSeed*(mnemonic: Mnemonic, password: KeystorePass = ""): KeySeed
  {.raises: [].} =

  # MnemonicSeed creates and returns a binary seed from the mnemonic.
  # We use the PBKDF2 function with a mnemonic sentence (in UTF-8 NFKD)
  # used as the password and the string SALT + passphrase (again in UTF-8 NFKD) used as the salt.
  # The iteration count is set to 2048 and HMAC-SHA512 is used as the pseudo-random function.
  # The length of the derived key is 512 bits (= 64 bytes).
  let salt = toNFKD("mnemonic" & password)
  KeySeed sha512.pbkdf2(mnemonic.string, salt, 2048, 64)
