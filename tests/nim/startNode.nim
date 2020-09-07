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

import chronos
import ../../src/nim_status/lib/shim as nim_shim

discard saveAccountAndLogin("", "", "{}", """{
  "WakuConfig": {
    "Enabled": true,
    "LightClient": true,
    "MinimumPoW": 0.001
  }
}""", "")

test_subscribe()
test_sendMessage("Hello")
test_sendMessage("World")

runForever()