import # nim libs
  strutils, unittest

import # vendor libs
  chronos

import # status libs
  ../status/extkeys/mnemonic, ./test_helpers

procSuite "mnemonic":
  test "mnemonic":
    let b = 'd'.byte
    let s = getBits b

    echo "BitSeq: ", s

    let mnemonic = mnemonicPhrase(EntropyStrength 128, Language.English).string
    echo "phrase:"
    echo mnemonic

    assert mnemonic.split(" ").len == 12
