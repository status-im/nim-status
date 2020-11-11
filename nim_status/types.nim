type SignalCallback* = proc(eventMessage: cstring): void {.cdecl.}

type Account* = ref object
  address*: string
  publicKey*: string
  privateKey*: string
