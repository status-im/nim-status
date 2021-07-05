import bitops
import parseutils
import strutils
import sequtils
import stew/bitseqs
import nimcrypto/sysrand as sysrand
import nimcrypto/sha2 as sha2
import account/types

type
  EntropyStrength = distinct uint
  BitSeq = seq[byte]
  Language* = enum
    English, French, Italian, Japanese

proc `$`*(s: BitSeq): string =
  var str: string
  for b in s:
    str.add(if b == 1: '1' else: '0')

  return str



proc getBits*(b: byte): BitSeq =
  var s = newSeq[byte]()
  for i in 0..7:
    let bit = (b shr i) and 1
    s.insert(bit, 0)

  return s

proc getBits*(byteSeq: seq[byte]): BitSeq =
  var s: BitSeq
  for b in byteSeq:
    s = concat(s, getBits(b))

  return s

proc getBits*(byteStr: string): BitSeq =
  var s: BitSeq
  for b in byteStr:
    let bits = getBits(b.byte)
    s = concat(s, bits)

  return s


# MnemonicPhrase returns a human readable seed for BIP32 Hierarchical Deterministic Wallets
proc mnemonicPhrase*(strength: int, language: Language): Mnemonic =
  # The mnemonic must encode entropy in a multiple of 32 bits.
  # With more entropy security is improved but the sentence length increases.
  # We refer to the initial entropy length as ENT. The recommended size of ENT is 128-256 bits.

  if strength mod 32 > 0 or strength < 128 or strength > 256:
    raise newException(Exception, "ErrInvalidEntropyStrength")

  # First, an initial entropy of ENT bits is generated
  var entropy = newSeq[byte](strength div 8)
  discard sysrand.randomBytes(addr entropy[0], strength div 8)
  var entropyBits = getBits(entropy)


  # A checksum is generated by taking the first bits of its SHA256 hash ( ENT / 32 )
  # This checksum is appended to the end of the initial entropy.
  let hash = sha256.digest(entropy)
  let checksumBitLength = strength div 32
  let checksum = getBits($hash)

  entropyBits = concat(entropyBits, checksum[0..3])

  const wordlist = staticRead("wordlists/english.txt")
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
