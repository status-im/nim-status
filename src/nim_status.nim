from status_go import nil

# TODO: test this in node-ffi?
# TODO: Create a nim proc for each status_go function

proc hashMessage*(message: cstring): cstring {.exportc.} =
  result = status_go.hashMessage(message)
