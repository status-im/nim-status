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
                     srcDir = "test/nim/",
                     outDir = "test/nim/build/",
                     params = "",
                     cmdParams = "",
                     lang = "c") =
  rmDir "data"
  rmDir "keystore"
  rmDir "noBackup"
  mkDir "data"
  mkDir "keystore"
  mkDir "noBackup"
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
    " --nimcache:nimcache/test/" & name &
    " --out:" & outDir & name &
    (if getEnv("NIMSTATUS_CFLAGS").strip != "": " --passC:\"" & getEnv("NIMSTATUS_CFLAGS") & "\"" else: "") &
    (if getEnv("PCRE_LDFLAGS").strip != "": " --passL:\"" & getEnv("PCRE_LDFLAGS") & "\"" else: "") &
    (if defined(windows): " --passL:\"-L" & getEnv("STATUSGO_LIB_DIR") & " -lstatus" & "\"" & (if getEnv("SQLCIPHER_LDFLAGS").strip != "": " --passL:\"" & getEnv("SQLCIPHER_LDFLAGS") & "\"" else: "") else: (if getEnv("SQLCIPHER_LDFLAGS").strip != "": " --passL:\"" & getEnv("SQLCIPHER_LDFLAGS") & "\"" else: "") & " --passL:\"-L" & getEnv("STATUSGO_LIB_DIR") & " -lstatus" & "\"") &
    (if getEnv("SSL_LDFLAGS").strip != "": " --passL:\"" & getEnv("SSL_LDFLAGS") & "\"" else: "") &
    (if defined(macosx): " --passL:-headerpad_max_install_names" else: "") &
    " --threads:on" &
    " --tlsEmulation:off" &
    " " &
    extra_params &
    " " &
    srcDir & name & ".nim" &
    " " &
    cmdParams
  if defined(macosx):
    exec "install_name_tool -add_rpath " & getEnv("STATUSGO_LIB_DIR") & " " & outDir & name
    exec "install_name_tool -change libstatus.dylib @rpath/libstatus.dylib " & outDir & name
  exec outDir & name

task tests, "Run all tests":
  buildAndRunTest "shims"
  buildAndRunTest "settings"
  buildAndRunTest "login_and_logout"
  buildAndRunTest "db_smoke"
  buildAndRunTest "waku_smoke"
  buildAndRunTest "callrpc"
  buildAndRunTest "migrations"
  buildAndRunTest "mailservers"
  buildAndRunTest "bip32"
  buildAndRunTest "contacts"
  buildAndRunTest "account"
