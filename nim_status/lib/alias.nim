from bitops import bitand, bitor, bitxor
import secp256k1
import stew/endians2

# For details: https://en.wikipedia.org/wiki/Linear-feedback_shift_register
type Lsfr* = ref object
  poly*: uint64
  data*: uint64

proc next*(self: Lsfr): uint64 =
  var bit: uint64 = 0
  for i in 0..64:
    if bitand(self.poly, 1.uint64 shl i) != 0:
      bit = bitxor(bit, self.data shr i)
  bit = bitand(bit, 1.uint64)
  self.data = bitor(self.data shl 1, bit)
  result = self.data

proc truncPubKey*(pubKey: string): uint64 =
  let rawKey = SkPublicKey.fromHex(pubKey).get.toRaw
  fromBytesBE(uint64, rawKey[25..32])
