{.passL:"vendor/status-go/build/bin/libstatus.a"}
when defined(macosx):
  {.passL: "-framework Foundation".}
  {.passL: "-framework Security".}
  {.passL: "-framework IOKit".}
  {.passL: "-framework CoreServices".}

import ../../src/nim_status/lib/shim as nim_shim
import ../../src/nim_status/go/shim as go_shim
import strutils

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
