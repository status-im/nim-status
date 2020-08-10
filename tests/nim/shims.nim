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

import ../../src/nim_status/lib/shim as nim_shim
import ../../src/nim_status/go/shim as go_shim
import strutils

# hashMessage

proc hashCmp(str1: string, str2: string, testSame: bool): void =
  if testSame:
    assert nim_shim.hashMessage(str1) == go_shim.hashMessage(str2)
  else:
    assert nim_shim.hashMessage(str1) != go_shim.hashMessage(str2)

hashCmp("", "", true)
hashCmp("a", "a", true)
hashCmp("ab", "ab", true)
hashCmp("abc", "abc", true)
hashCmp("aBc", "aBc", true)
hashCmp("Abc", "abC", false)
hashCmp("0xffffff", "0xffffff", true)
hashCmp("0xFFFFFF", "0xffffff", true)
hashCmp("0xffffff", "0xFFFFFF", true)
hashCmp("0x" & "abc".toHex, "abc", true)
hashCmp("0x616263", "abc", true)
hashCmp("abc", "0x" & "abc".toHex, true)
hashCmp("abc", "0x616263", true)
hashCmp("0xabc", "0xabc", true)
hashCmp("0xaBc", "0xaBc", true)
hashCmp("0xAbc", "0xabC", false)
hashCmp("0xabcd", "0xabcd", true)
hashCmp("0xaBcd", "0xaBcd", true)
hashCmp("0xAbcd", "0xabcD", true)
hashCmp("0xverybadhex", "0xverybadhex", true)
hashCmp("0Xabcd", "0Xabcd", true)
hashCmp("0xabcd", "0Xabcd", false)
hashCmp("0Xabcd", "0xabcd", false)
assert nim_shim.hashMessage("0Xabcd") != nim_shim.hashMessage("0xabcd")
assert go_shim.hashMessage("0Xabcd") != go_shim.hashMessage("0xabcd")

const pubKey_1 = "0x0441ccda1563d69ac6b2e53718973c4e7280b4a5d8b3a09bb8bce9ebc5f082778243f1a04ec1f7995660482ca4b966ab0044566141ca48d7cdef8b7375cd5b7af5"
const pubKey_2 = "0x04ee10b0d66ccb9e3da3a74f73f880e829332f2a649e759d7c82f08b674507d498d7837279f209444092625b2be691e607c5dc3da1c198d63e430c9c7810516a8f"
const pubKey_3 = "0x046ffe9547ebceda7696ef5a67dc28e330b6fc3911eb6b1996c9622b2d7f0e8493c46fbd07ab591d62244e36c0d051863f86b1d656361d347a830c4239ef8877f5"
const pubKey_4 = "0x049bdc0016c51ec7b788db9ab0c63a1fbf3f873d2f3e3b85bf1cf034ab5370858ff31894017f56705de03dbaabf3f9811193fd5323376ec38a688cc306a5bf3ef7"
const pubKey_5 = "0x04ffdb0fef8f8e3bd899250538bc3c651090aa5b579e9cefa38f6896d599dcd1f1326ec5cd8f749e0a7d3c0ce1c8f9126bd4be985004319769de1e83cbca9301bf"
const badKey_1 = "xyz"
const badKey_2 = "0x06abcd"
const badKey_3 = "0x06ffdb0fef8f8e3bd899250538bc3c651090aa5b579e9cefa38f6896d599dcd1f1326ec5cd8f749e0a7d3c0ce1c8f9126bd4be985004319769de1e83cbca9301bf"
const badKey_4 = "0x04ffdb0fef8f8e3bd899250538bc3c651090aa5b579e9cefa38f6896d599dcd1f1326ec5cd8f749e0a7d3c0ce1c8f9126bd4be985004319769de1e83cbca930xyz"

# generateAlias

proc generateAliasCmp(pubKey: string): void =
  assert nim_shim.generateAlias(pubKey) == go_shim.generateAlias(pubKey)

generateAliasCmp(pubKey_1)
generateAliasCmp(pubKey_2)
generateAliasCmp(pubKey_3)
generateAliasCmp(pubKey_4)
generateAliasCmp(pubKey_5)
generateAliasCmp(badKey_1)
generateAliasCmp(badKey_2)
generateAliasCmp(badKey_3)
generateAliasCmp(badKey_4)
