import # std libs
  std/[strutils, random, times]

import # status libs
  ../../extkeys/mnemonic, ./signing_phrases

proc generateSigningPhrase*(count: int): string =
  let now = getTime()
  var rng = initRand(now.toUnix * 1000000000 + now.nanosecond)
  var phrases: seq[string] = @[]

  for i in 1..count:
    phrases.add(rng.sample(signing_phrases.phrases))

  result = phrases.join(" ")

proc mnemonicPhraseLengthToEntropyStrength*(length: int): EntropyStrength =
  # MnemonicPhraseLengthToEntropyStrength returns the entropy strength for a
  # given mnemonic length
  if length < 12 or length > 24 or length mod 3 != 0:
    return EntropyStrength(0)

  let bitsLength = length * 11
  let checksumLength = bitsLength mod 32

  return EntropyStrength(bitsLength - checksumLength)

# TODO: Add ValidateKeystoreExtendedKey
# https://github.com/status-im/status-go/blob/287e5cdf79fc06d5cf5c9d3bd3a99a1df1e3cd10/accounts/generator/utils.go#L24-L34
