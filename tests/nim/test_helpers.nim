import chronos, unittest

template asyncTest*(name, body: untyped) =
  test name:
    proc scenario {.async.} = body
    waitFor scenario()

template procSuite*(name, body: untyped) =
  proc suitePayload =
    suite name:
      body
  suitePayload()
