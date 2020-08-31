proc c_malloc*(size: csize_t): pointer {.importc: "malloc", header: "<stdlib.h>".}
