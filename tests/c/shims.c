#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include "shims.h"


void hashCmp(char* str1, char* str2, bool testSame) {
  if (testSame) {
    assert(strcmp(nim_hashMessage(str1), go_hashMessage(str2)) == 0);
  } else {
    assert(strcmp(nim_hashMessage(str1), go_hashMessage(str2)) != 0);
  }
}

int main(int argc, char* argv[]) {
  // NimMain initializes Nim's garbage collector and runs top level statements
  // in the compiled library
  NimMain();

  hashCmp("", "", true);
  hashCmp("a", "a", true);
  hashCmp("ab", "ab", true);
  hashCmp("abc", "abc", true);
  hashCmp("aBc", "aBc", true);
  hashCmp("Abc", "abC", false);
  hashCmp("0xffffff", "0xffffff", true);
  hashCmp("0xFFFFFF", "0xffffff", true);
  hashCmp("0xffffff", "0xFFFFFF", true);
  hashCmp("0x616263", "abc", true);
  hashCmp("abc", "0x616263", true);
  hashCmp("0xabc", "0xabc", true);
  hashCmp("0xaBc", "0xaBc", true);
  hashCmp("0xAbc", "0xabC", false);
  hashCmp("0xabcd", "0xabcd", true);
  hashCmp("0xaBcd", "0xaBcd", true);
  hashCmp("0xAbcd", "0xabcD", true);
  hashCmp("0xverybadhex", "0xverybadhex", true);
  hashCmp("0Xabcd", "0Xabcd", true);
  hashCmp("0xabcd", "0Xabcd", false);
  hashCmp("0Xabcd", "0xabcd", false);
  assert(strcmp(nim_hashMessage("0Xabcd"), nim_hashMessage("0xabcd")) != 0);
  assert(strcmp(go_hashMessage("0Xabcd"), go_hashMessage("0xabcd")) != 0);

  return 0;
}
