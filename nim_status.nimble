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

proc buildAndRun(name: string,
                 srcDir = "test/",
                 outDir = "test/build/",
                 run = true,
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
    # (if getEnv("RLN_STATIC").strip != "false": (if defined(windows): " --dynlibOverride:vendor\\rln\\target\\debug\\rln" else: " --dynlibOverride:vendor/rln/target/debug/librln") else: "") &
    # usually `--dynlibOverride` is used in case of static linking and so would
    # be used conditionally (see commented code above), but because
    # `vendor/nim-waku/waku/v2/protocol/waku_rln_relay/rln.nim` specifies the
    # library with a relative path prefix (which isn't valid relative to root
    # of this repo) it needs to be used in the case of shared or static linking
    (if defined(windows): " --dynlibOverride:vendor\\rln\\target\\debug\\rln" else: " --dynlibOverride:vendor/rln/target/debug/librln") &
    " --define:ssl" &
    (if getEnv("SSL_STATIC").strip != "false": " --dynlibOverride:ssl" else: "") &
    " --linetrace:on" &
    " --nimcache:nimcache/test/" & name &
    " --out:" & outDir & name &
    (if getEnv("NIMSTATUS_CFLAGS").strip != "": " --passC:\"" & getEnv("NIMSTATUS_CFLAGS") & "\"" else: "") &
    (if getEnv("PCRE_LDFLAGS").strip != "": " --passL:\"" & getEnv("PCRE_LDFLAGS") & "\"" else: "") &
    (if getEnv("RLN_LDFLAGS").strip != "": " --passL:\"" & getEnv("RLN_LDFLAGS") & "\"" else: "") &
    (if getEnv("SQLCIPHER_LDFLAGS").strip != "": " --passL:\"" & getEnv("SQLCIPHER_LDFLAGS") & "\"" else: "") &
    (if getEnv("SSL_LDFLAGS").strip != "": " --passL:\"" & getEnv("SSL_LDFLAGS") & "\"" else: "") &
    " --stacktrace:on" &
    " --threads:on" &
    " --tlsEmulation:off" &
    " " &
    extra_params &
    " " &
    srcDir & name & ".nim" &
    " " &
    cmdParams
  if run:
    exec outDir & name

task chat, "Build and run the example chat client":
  buildAndRun "chat", "examples/", "build/"

task chat_build, "Build the example chat client":
  buildAndRun "chat", "examples/", "build/", false

task tests, "Build and run all tests":
  buildAndRun "test_all"
