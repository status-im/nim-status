import ../../nim_status/lib/account
import test_helpers
import utils
import eth/[keys, p2p]

import chronos
import os
import unittest

var success = false


procSuite "nim_status":
  asyncTest "account":
    resetDirectories() # Recreates the data and nobackup dir
    init()

    # Single RNG instance for the application - will be seeded on construction
    # and avoid using system resources (such as urandom) after that
    var rng = keys.newRng()

    let account = createAccount(rng)


    let pubKey = derivePubKeyFromPrivateKey(account.privateKey)


    let signature = signMessage(account.privateKey, "Hello world")

    check:
      account.address != ""
      account.publicKey != ""
      account.privateKey != ""
      account.publicKey == pubKey
      signature != ""

