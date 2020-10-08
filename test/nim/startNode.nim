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

import ../../nim_status/lib
from ../../nim_status/lib/waku/node as wakuNode import nil
import test_helpers

import
  chronicles, chronos, stew/shims/net as stewNet, stew/byteutils,
  eth/[keys, p2p],
  waku/protocol/v1/waku_protocol,
  unittest

# Using a hardcoded symmetric key for encryption of the payload for the sake
# of simplicity.
var symKey: SymKey
symKey[31] = 1

# Asymmetric keypair to sign the payload.
let signKeyPair = KeyPair.random(wakuNode.rng[])

let
  topic = [byte 0, 0, 0, 0]
  filter = initFilter(symKey = some(symKey), topics = @[topic])

proc saveAccountAndLogin() =
  {.gcsafe.}: # test-ONLY workaround re: chronos/asyncmacro2's `asyncSingleProc`
    discard lib.saveAccountAndLogin("", "", "{}", """{
      "WakuConfig": {
      "Enabled": true,
      "LightClient": true,
      "MinimumPoW": 0.001
      }
    }""", "")

proc sendMessage(message: string) =
  {.gcsafe.}: # test-ONLY workaround re: chronos/asyncmacro2's `asyncSingleProc`
    wakuNode.post(symKey, signKeyPair, topic, message)

procSuite "nim_status":
  asyncTest "waku: basic subscribe and send":
    let futures = [newFuture[int](), newFuture[int]()]
    var successes = 0

    proc subscribe() =
      {.gcsafe.}: # test-ONLY workaround re: chronos/asyncmacro2's `asyncSingleProc`
        proc handler(msg: ReceivedMessage) =
          if msg.decoded.src.isSome():
            let payload = string.fromBytes(msg.decoded.payload)
            echo "Received message from ", $msg.decoded.src.get(), ": ",
              payload
            if payload == "Hello":
              futures[0].complete(1)
              successes += 1
            if payload == "World":
              futures[1].complete(1)
              successes += 1
        wakuNode.subscribe(filter, handler)

    saveAccountAndLogin()
    subscribe()
    sendMessage("Hello")
    sendMessage("World")

    check:
      await allFutures(futures).withTimeout(5.minutes)
      successes == 2
