mode = ScriptMode.Verbose

version       = "0.1.0"
author        = "Status Research & Development GmbH"
description   = "Nim implementation of the Status protocol"
license       = "MIT"
skipDirs      = @["test"]

requires "nim >= 1.2.0",
  "chroma",
  "chronicles",
  "chronos",
  "confutils",
  "eth",
  "nimPNG",
  "nimage",
  "nimcrypto",
  "secp256k1",
  "stew",
  "waku"

import strutils

proc buildAndRunTest(name: string,
                     srcDir = "test/",
                     outDir = "test/build/",
                     params = "",
                     cmdParams = "",
                     lang = "c") =
  rmDir outDir
  mkDir outDir
  # allow something like "nim test --verbosity:0 --hints:off beacon_chain.nims"
  var extra_params = params
  for i in 2..<paramCount():
    extra_params &= " " & paramStr(i)
  exec "nim " &
    lang &
    " --debugger:native" &
    " --define:chronicles_line_numbers" &
    " --define:debug" &
    (if getEnv("PCRE_STATIC").strip != "false": " --define:usePcreHeader --dynlibOverride:pcre" elif defined(windows): " --define:usePcreHeader" else: "") &
    " --define:ssl" &
    (if getEnv("SSL_STATIC").strip != "false": " --dynlibOverride:ssl" else: "") &
    " --linetrace:on" &
    " --nimcache:nimcache/test/" & name &
    " --out:" & outDir & name &
    (if getEnv("NIMSTATUS_CFLAGS").strip != "": " --passC:\"" & getEnv("NIMSTATUS_CFLAGS") & "\"" else: "") &
    (if getEnv("PCRE_LDFLAGS").strip != "": " --passL:\"" & getEnv("PCRE_LDFLAGS") & "\"" else: "") &
    (if getEnv("SQLCIPHER_LDFLAGS").strip != "": " --passL:\"" & getEnv("SQLCIPHER_LDFLAGS") & "\"" else: "") &
    (if getEnv("SSL_LDFLAGS").strip != "": " --passL:\"" & getEnv("SSL_LDFLAGS") & "\"" else: "") &
    (if defined(macosx): " --passL:-headerpad_max_install_names" else: "") &
    " --stacktrace:on" &
    " --threads:on" &
    " --tlsEmulation:off" &
    " " &
    extra_params &
    " " &
    srcDir & name & ".nim" &
    " " &
    cmdParams
  exec outDir & name

task tests, "Run all tests":
  #buildAndRunTest "test_all"
  buildAndRunTest "client"
