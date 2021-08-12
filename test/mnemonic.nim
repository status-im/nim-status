import # std libs
  std/[strutils, unittest]

import # vendor libs
  chronos

import # status lib
  status/private/[common, extkeys/mnemonic]

import # test modules
  ./test_helpers

procSuite "mnemonic":
  test "mnemonic":
    let b = 'd'.byte
    let s = getBits b

    echo "BitSeq: ", s

    let mnemonicResult = mnemonicPhrase(EntropyStrength 128, Language.English)
    check mnemonicResult.isOk
    let mnemonic = mnemonicResult.get.string
    echo "phrase:"
    echo mnemonic

    assert mnemonic.split(" ").len == 12
