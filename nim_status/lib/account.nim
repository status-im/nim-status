import secp256k1
import eth/[keys, p2p]
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
