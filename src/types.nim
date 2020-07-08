type
  GoString* {.exportc:"GoString".} = object 
    str*: cstring
    length*: cint

type SignalCallback* {.exportc:"SignalCallback"} = proc(eventMessage: cstring): void {.cdecl.}
