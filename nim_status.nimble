# Package

version       = "0.1.0"
author        = "Status Research & Development GmbH"
description   = "Nim implementation of the Status protocol"
license       = "MIT"
srcDir        = "src"
bin           = @[""]
skipDirs       = @["test"]

# Deps

requires "nim >= 1.0.0"


### Helper functions
proc buildAndRunBinary(name: string, srcDir = "./", params = "", cmdParams = "", lang = "c") =
  if not dirExists "build":
    mkDir "build"
  # allow something like "nim test --verbosity:0 --hints:off beacon_chain.nims"
  var extra_params = params
  for i in 2..<paramCount():
    extra_params &= " " & paramStr(i)
  exec "nim " & lang & " --out:./build/" & name & " -r " & extra_params & " " & srcDir & name & ".nim" & " " & cmdParams

### tasks
task test, "Run all tests":
  buildAndRunBinary "test1", "tests/"
