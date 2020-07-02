#include <stdio.h>
#include <string.h>
#include "nim_status.h"

int main(int argc, char* argv[]) {
  NimMain();
  const char* theMessage = hashMessage("Hello World!");
  printf("%s\n", theMessage);

  char* pubKey = "0x0441ccda1563d69ac6b2e53718973c4e7280b4a5d8b3a09bb8bce9ebc5f082778243f1a04ec1f7995660482ca4b966ab0044566141ca48d7cdef8b7375cd5b7af5";
  struct GoString p1 = {pubKey, strlen(pubKey)}; 
  const char* theIdenticon = identicon(p1);
  printf("%s\n", theIdenticon);


  // TODO: test signals
  // TODO: tests GC strings

  return 0;
}