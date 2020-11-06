import secp256k1
import stew/byteutils
import eth/keys
import ../types

# Creates a new random account with its private key, public key and address
# rng: use a single RNG instance for the application - will be seeded on construction
    # and avoid using system resources (such as urandom) after that
    # To create, just do: `keys.newRng()`
proc createAccount*(rng: ref BrHmacDrbgContext): Account =
  let privateKey = PrivateKey.random(rng[])
  let publicKey = privateKey.toPublicKey()
  let address = publicKey.toAddress()

  result = Account(
    address: address,
    publicKey: $publicKey,
    privateKey: $privateKey
  )

proc derivePubKeyFromPrivateKey*(privateKey: string): string =
  let privKey = PrivateKey.fromRaw(hexToSeqByte(privateKey)).get()
  return $privKey.toPublicKey()

proc signMessage*(privateKey: string, message: string): string =
  let privKey = PrivateKey.fromRaw(hexToSeqByte(privateKey)).get()

  let bytesMsg = message.toBytes()

  return $keys.sign(privKey, bytesMsg)
