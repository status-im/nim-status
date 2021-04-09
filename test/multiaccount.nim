import # nim libs
  os, strutils, unittest

import # vednor libs
  chronos, eth/[keys, p2p]


import # nim-status libs
  ../nim_status/account,
  ../nim_status/mnemonic,
  ../nim_status/multiaccount,
  ./test_helpers

procSuite "multiaccount":
  test "multiaccount":
    let entropyStrength = mnemonicPhraseLengthToEntropyStrength(12)
    assert entropyStrength == 128

    let passphrase = ""
    let multiAccounts = generateAndDeriveAddresses(12, 1, passphrase, @["m/44'/60'/0'/0", "m/44'/60'/0'/0/0", "m/43'/60'/1581'/0'/0"])

    #assert len(multiAccounts) == 5

    let multiAcc = multiAccounts[0]
    assert len(multiAcc.accounts) == 3

    let password = "qwerty"
    let dir = "test_accounts"
    removeDir(dir)
    createDir(dir)
    storeDerivedAccounts(multiAccounts[0], password, dir)

    let chatAddress = multiAcc.accounts[2].address

    let chatAccount = loadAccount(chatAddress, password, dir)

    echo "chatAccount:"
    echo chatAccount

    assert chatAccount.address == chatAddress
