### Package
version       = "0.1.0"
author        = "Status Research & Development GmbH"
description   = "Nim implementation of the Status protocol"
license       = "MIT"
srcDir        = "src"
bin           = @[""]
skipDirs       = @["test"]

### Deps
requires "nim >= 1.0.0"

### Helper functions
proc buildAndRunBinary(name: string, srcDir = "./", params = "", cmdParams = "", lang = "c") =
  rmDir "data"
  rmDir "keystore"
  rmDir "noBackup"
  mkDir "data"
  mkDir "keystore"
  mkDir "noBackup"
  if not dirExists "tests/nim/build":
    mkDir "tests/nim/build"
  # allow something like "nim test --verbosity:0 --hints:off beacon_chain.nims"
  var extra_params = params
  for i in 2..<paramCount():
    extra_params &= " " & paramStr(i)
  exec "nim " & lang & " --out:./tests/nim/build/" & name & " " & extra_params & " " & srcDir & name & ".nim" & " " & cmdParams
  if defined(macosx):
    exec "install_name_tool -add_rpath " & getEnv("STATUSGO_LIBDIR") & " tests/nim/build/" & name
    exec "install_name_tool -change libstatus.dylib @rpath/libstatus.dylib tests/nim/build/" & name
  echo "Executing 'tests/nim/build/" & name & "'"
  exec "tests/nim/build/" & name

### Tasks
task test, "Run all tests":
  buildAndRunBinary "shims", "tests/nim/"
  buildAndRunBinary "login", "tests/nim/"
