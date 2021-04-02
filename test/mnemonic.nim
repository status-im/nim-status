import # nim libs
  os, strutils, unittest

import # vednor libs
  chronos, eth/[keys, p2p]


import # nim-status libs
  ../nim_status/mnemonic,
  ./test_helpers

procSuite "mnemonic":
  test "mnemonic":
    let b: byte = cast[byte]('d')
    let s = getBits b

    echo "BitSeq: ", s

    let mnemonic = mnemonicPhrase(128, Language.English)
    echo "phrase:"
    echo mnemonic
    
    assert mnemonic.split(" ").len == 12