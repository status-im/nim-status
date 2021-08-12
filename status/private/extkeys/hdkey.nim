{.push raises: [Defect].}

import # vendor libs
  eth/keys, nimcrypto/hmac, secp256k1,
  stew/[byteutils, results]

import # status modules
  ../common, ../util,
  ./paths, ./types, ./utils

const
  masterSecret*: string = "Bitcoin seed"

proc child(self: ExtendedPrivKey, child: PathLevel): ExtKeyResult[
  ExtendedPrivKey] =

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

  var
    pk = self.secretKey.toRaw()[0..^1]
    sk = ? SkSecretKey.fromRaw(secretKey).mapErrTo(InvalidPrivateKey)

  ? sk.tweakAdd(pk).mapErrTo(InvalidPrivateKey)

  ok ExtendedPrivKey(
    secretKey: sk,
    chainCode: chainCode
  )

proc derive*(k: ExtendedPrivKey, path: KeyPath): ExtKeyResult[ExtendedPrivKey] =
  var extKey = k
  for child in path.pathNodes:
    extKey = ?extKey.child(?child)

  ok extKey

proc newMaster*(seed: Keyseed): ExtKeyResult[ExtendedPrivKey] =

  # NewMaster creates new master node, root of HD chain/tree.
  # Both master and child nodes are of ExtendedKey type, and all the children
  # derive from the root node.
  let lseed = openArray[byte](seed).len
  if lseed < MIN_SEED_BYTES or lseed > MAX_SEED_BYTES:
    return err InvalidSeedLength

  splitHMAC(string.fromBytes(openArray[byte](seed)), masterSecret)

proc toExtendedKey*(secretKey: SkSecretKey): ExtendedPrivKey
  {.raises: [].} =

  ExtendedPrivKey(secretKey: secretKey)
