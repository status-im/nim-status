import ../../src/nim_status/c/lib/shim as nim_shim

let nim_hashMessage {.exportc.} = nim_shim.hashMessage

import ../../src/nim_status/c/go/shim as go_shim

let go_hashMessage {.exportc.} = go_shim.hashMessage
