#include <stdio.h>
#include <string.h>
#include "nim_status.h"

int main(int argc, char* argv[]) {
  NimMain();
  const char* message = hashMessage("Hello World!");
  printf("%s\n", message);

  // TODO: test signals
  // TODO: tests GC strings

  return 0;
}