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

proc buildAndRunTest(name: string, srcDir = "tests/nim/", outDir = "tests/nim/build/", params = "", cmdParams = "", lang = "c") =
  rmDir "data"
  rmDir "keystore"
  rmDir "noBackup"
  mkDir "data"
  mkDir "keystore"
  mkDir "noBackup"
  if not dirExists outDir:
    mkDir outDir
  # allow something like "nim test --verbosity:0 --hints:off beacon_chain.nims"
  var extra_params = params
  for i in 2..<paramCount():
    extra_params &= " " & paramStr(i)
  exec "nim " & lang & " --out:" & outDir & name & " " & extra_params & " " & srcDir & name & ".nim" & " " & cmdParams
  if defined(macosx):
    exec "install_name_tool -add_rpath " & getEnv("STATUSGO_LIB_DIR") & " " & outDir & name
    exec "install_name_tool -change libstatus.dylib @rpath/libstatus.dylib " & outDir & name
  echo "Executing '" & outDir & name & "'"
  exec outDir & name

task tests, "Run all tests":
  buildAndRunTest "shims"
  buildAndRunTest "startNode"
  buildAndRunTest "login"
