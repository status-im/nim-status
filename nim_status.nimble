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
  exec "nim " & lang & " --out:./tests/nim/build/" & name & " -r " & extra_params & " " & srcDir & name & ".nim" & " " & cmdParams

### Tasks
task test, "Run all tests":
  buildAndRunBinary "shims", "tests/nim/"
  buildAndRunBinary "login", "tests/nim/"
