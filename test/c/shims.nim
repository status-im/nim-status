import ../../nim_status/c/shim_impl as nim_shim

let nim_hashMessage {.exportc.} = nim_shim.hashMessage
let nim_generateAlias {.exportc.} = nim_shim.generateAlias
let nim_identicon {.exportc.} = nim_shim.identicon

import ../../nim_status/c/go/shim_impl as go_shim

let go_hashMessage {.exportc.} = go_shim.hashMessage
let go_generateAlias {.exportc.} = go_shim.generateAlias
let go_identicon {.exportc.} = go_shim.identicon
