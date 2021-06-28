import # nim libs
  os, unittest

import # vednor libs
  chronos, eth/[keys, p2p]

import # nim-status libs
  ../nim_status/[account, multiaccount], ./test_helpers


procSuite "multiaccount":
  test "multiaccount":
    let entropyStrength = mnemonicPhraseLengthToEntropyStrength(12)
    assert entropyStrength == 128

    let passphrase = ""
    let multiAccounts = generateAndDeriveAddresses(12, 1, passphrase, @[PATH_WALLET_ROOT, PATH_DEFAULT_WALLET, PATH_WHISPER])

    #assert len(multiAccounts) == 5

    let multiAcc = multiAccounts[0]
    assert len(multiAcc.accounts) == 3

    let password = "qwerty"
    let dir = "test_accounts"

    createDir(dir)

    storeDerivedAccounts(multiAccounts[0], password, dir, workfactor = 100)

    let chatAddress = multiAcc.accounts[2].address

    let chatAccount = loadAccount(chatAddress, password, dir)

    echo "chatAccount:"
    echo chatAccount

    assert chatAccount.address == chatAddress

    removeDir(dir)
