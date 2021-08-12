import # std libs
  std/[hashes, strformat, typetraits]

import # vendor libs
  secp256k1

import
  ../common

const
  MIN_SEED_BYTES* = 16 # 128 bits
    # MinSeedBytes is the minimum number of bytes allowed for a seed to a
    # master node.
  MAX_SEED_BYTES* = 64 # 512 bits
    # MaxSeedBytes is the maximum number of bytes allowed for a seed to a
    # master node.

type
  Mnemonic* = distinct string

  KeySeed* = distinct seq[byte]

  KeystorePass* = string

  KeyPath* = distinct string

  PathLevel* = distinct uint32

  ExtendedPrivKey* = object
    secretKey*: SkSecretKey
    chainCode*: seq[byte]

  ExtKeyError* = enum
    InvalidKeyPath      = "ek: invalid key path"
    InvalidKeyPathIndex = "ek: invalid key path index number"
    InvalidPrivateKey   = "ek: invalid private key"
    InvalidSeedLength   = static("ek: the recommended size of seed is " &
                            fmt"{MIN_SEED_BYTES}-{MAX_SEED_BYTES} bits")

  ExtKeyResult*[T] = Result[T, ExtKeyError]

proc `==`*(a, b: KeyPath): auto = distinctBase(a) == distinctBase(b)

proc `$`*(k: KeyPath): auto = distinctBase(k)

proc hash*(k: KeyPath): auto = distinctBase(k).hash
