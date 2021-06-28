import
  std/[parseutils, strutils],
  normalize,
  secp256k1,
  stew/[results, byteutils],
  nimcrypto/[sha2, pbkdf2, hash, hmac],
  account/[types, paths],
  eth/keys

export KeySeed, Mnemonic, SecretKeyResult, KeyPath

type Account* = ref object
  keyUid*: string
  address*: string
  publicKey*: string
  privateKey*: string
  path*: string

proc `$`*(acc: Account): string =
  echo "Account begin"
  echo "Addr: ", acc.address
  echo "PrivateKey: ", acc.privateKey
  echo "PublicKey: ", acc.publicKey
  echo "Path: ", acc.path
  echo "Account end"


proc getSeed*(mnemonic: Mnemonic, password: KeystorePass = ""): KeySeed =
  let salt = toNFKD("mnemonic" & password)
  KeySeed sha512.pbkdf2(mnemonic.string, salt, 2048, 64)

proc child(self: ExtendedPrivKey, child: PathLevel): ExtendedPrivKeyResult =
  var hctx: HMAC[sha512]
  hctx.init(self.chainCode)
  if child.isNonHardened():
    hctx.update(self.secretKey.toPublicKey().toRawCompressed())
  else:
    hctx.update([0.byte])
    hctx.update(self.secretKey.toRaw())
  hctx.update(child.toBEBytes());
  let hmacResult = hctx.finish();

  var secretKey = hmacResult.data[0..31]
  let chainCode = hmacResult.data[32..63]

  var pk = self.secretKey.toRaw()[0..^1]
  var sk = SkSecretKey.fromRaw(secretKey)
  if sk.isOk:
    let tweakResult = tweakAdd(sk.get(), pk)
    if tweakResult.isErr: return err($tweakResult.error())
    return ok(ExtendedPrivKey(
      secretKey: sk.get(),
      chainCode: chainCode
    ))

  err($sk.error())

proc derive*(seed: Keyseed, path: KeyPath): SecretKeyResult =
  let hmacResult = sha512.hmac("Bitcoin seed", seq[byte] seed)
  let secretKey = hmacResult.data[0..31]
  let chainCode = hmacResult.data[32..63]
  let sk = SkSecretKey.fromRaw(secretKey)
  if sk.isErr(): return err("Invalid secret key")

  var extPrivK = ExtendedPrivKey(
    secretKey: sk.get(),
    chainCode: chainCode
  )

  for child in path.pathNodes:
    if child.isErr(): return err(child.error().cstring)

    let r = extPrivK.child(child.get())
    if r.isErr(): return err(r.error().cstring)
    extPrivK = r.get()

  ok(extPrivK.secretKey)

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
