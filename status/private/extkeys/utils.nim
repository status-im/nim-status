{.push raises: [Defect].}

import # vendor libs
  eth/keys, nimcrypto/hmac, secp256k1,
  stew/[byteutils, results]

import # status modules
  ./types

proc splitHMAC*(seed: string, salt: string): ExtKeyResult[ExtendedPrivKey] =
  let hmacResult = sha512.hmac(salt, seed.toBytes())
  let secretKey = hmacResult.data[0..31]
  let chainCode = hmacResult.data[32..63]
  let sk = SkSecretKey.fromRaw(secretKey)
  if sk.isErr: return err InvalidPrivateKey

  var extPrivK = ExtendedPrivKey(
    secretKey: sk.get,
    chainCode: chainCode
  )

  ok extPrivK
