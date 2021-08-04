{.push raises: [Defect].}

import # std libs
  std/bitops

import # vendor libs
  secp256k1, stew/endians2, strformat

import # status modules
  ./alias/data, ./util

# For details: https://en.wikipedia.org/wiki/Linear-feedback_shift_register
type Lsfr = ref object
  poly*: uint64
  data*: uint64

proc next(self: Lsfr): uint64 {.raises: [].} =
  var bit: uint64 = 0
  for i in 0..64:
    if bitand(self.poly, 1.uint64 shl i) != 0:
      bit = bitxor(bit, self.data shr i)
  bit = bitand(bit, 1.uint64)
  self.data = bitor(self.data shl 1, bit)
  result = self.data

proc truncPubKey(pubKey: string): uint64 =
  let rawKey = SkPublicKey.fromHex(pubKey).get.toRaw
  fromBytesBE(uint64, rawKey[25..32])

proc generateAlias*(pubKey: string): string {.raises: [RegexError].} =
  ## generateAlias returns a 3-words generated name given a hex encoded (prefixed with 0x) public key.
  ## We ignore any error, empty string result is considered an error.
  result = ""
  if isPubKey(pubKey):
    try:
      let seed = truncPubKey(pubKey)
      const poly: uint64 = 0xB8
      let generator = Lsfr(poly: poly, data: seed)
      let adjective1 = adjectives[generator.next mod adjectives.len]
      let adjective2 = adjectives[generator.next mod adjectives.len]
      let animal = animals[generator.next mod animals.len.uint64]
      result = fmt("{adjective1} {adjective2} {animal}")
    except:
      discard
