from bitops import bitand, bitor, bitxor
import secp256k1
import stew/endians2

# For details: https://en.wikipedia.org/wiki/Linear-feedback_shift_register
type Lsfr* = ref object
  poly*: uint64
  data*: uint64

proc next*(self: Lsfr): uint64 =
  const one: uint64 = 1
  const limit: uint64 = 64
  var bit: uint64 = 0
  var i: uint64 = 0
  while i < limit:
    if bitand(self.poly, one shl i) != 0:
      bit = bitxor(bit, self.data shr i)
    i += one
  bit = bitand(bit, one)
  self.data = bitor(self.data shl one, bit)
  result = self.data

proc truncPubKey*(pubKey: string): uint64 =
  let rawKey = SkPublicKey.fromHex(pubKey).get.toRaw
  fromBytesBE(uint64, rawKey[25..32])
