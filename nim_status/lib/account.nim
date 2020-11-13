import
  std/[parseutils, strutils],
  normalize,
  secp256k1,
  stew/[results],
  nimcrypto/[sha2, pbkdf2, hash, hmac],
  account/[types, paths]

export KeySeed, Mnemonic, SecretKeyResult, KeyPath

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
    if child.isErr(): return err(child.error())
      
    let r = extPrivK.child(child.get())
    if r.isErr(): return err(r.error())
    extPrivK = r.get()

  ok(extPrivK.secretKey)


