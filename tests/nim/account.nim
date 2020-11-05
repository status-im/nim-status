from os import getEnv
{.passL: "-L" & getEnv("STATUSGO_LIBDIR")}
{.passL: "-lstatus"}
when defined(linux):
  {.passL: "-lcrypto"}
  {.passL: "-lssl"}
  {.passL: "-lpcre"}
when defined(macosx):
  {.passL: "bottles/openssl/lib/libcrypto.a"}
  {.passL: "bottles/openssl/lib/libssl.a"}
  {.passL: "bottles/pcre/lib/libpcre.a"}
  {.passL: "-framework CoreFoundation".}
  {.passL: "-framework CoreServices".}
  {.passL: "-framework IOKit".}
  {.passL: "-framework Security".}
  {.passL: "-headerpad_max_install_names".}

import ../../src/nim_status
import test_helpers
import utils
import secp256k1
import eth/[keys, p2p]

import chronos
import os
import unittest

procSuite "nim_status":
  asyncTest "account":
    resetDirectories() # Recreates the data and nobackup dir
    init()

    # Single RNG instance for the application - will be seeded on construction
    # and avoid using system resources (such as urandom) after that
    var rng = keys.newRng()

    let account = createAccount(rng)

    check:
      account.address != ""
      account.publicKey != ""
      account.privateKey != ""

