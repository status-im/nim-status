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

void generateAliasCmp(char* pubKey) {
  assert(strcmp(nim_generateAlias(pubKey), go_generateAlias(pubKey)) == 0);
}

int main(int argc, char* argv[]) {
  // NimMain initializes Nim's garbage collector and runs top level statements
  // in the compiled library
  NimMain();

  // hashMessage

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

  char* pubKey_1 = "0x0441ccda1563d69ac6b2e53718973c4e7280b4a5d8b3a09bb8bce9ebc5f082778243f1a04ec1f7995660482ca4b966ab0044566141ca48d7cdef8b7375cd5b7af5";
  char* pubKey_2 = "0x04ee10b0d66ccb9e3da3a74f73f880e829332f2a649e759d7c82f08b674507d498d7837279f209444092625b2be691e607c5dc3da1c198d63e430c9c7810516a8f";
  char* pubKey_3 = "0x046ffe9547ebceda7696ef5a67dc28e330b6fc3911eb6b1996c9622b2d7f0e8493c46fbd07ab591d62244e36c0d051863f86b1d656361d347a830c4239ef8877f5";
  char* pubKey_4 = "0x049bdc0016c51ec7b788db9ab0c63a1fbf3f873d2f3e3b85bf1cf034ab5370858ff31894017f56705de03dbaabf3f9811193fd5323376ec38a688cc306a5bf3ef7";
  char* pubKey_5 = "0x04ffdb0fef8f8e3bd899250538bc3c651090aa5b579e9cefa38f6896d599dcd1f1326ec5cd8f749e0a7d3c0ce1c8f9126bd4be985004319769de1e83cbca9301bf";
  char* badKey_1 = "xyz";
  char* badKey_2 = "0x06abcd";
  char* badKey_3 = "0x06ffdb0fef8f8e3bd899250538bc3c651090aa5b579e9cefa38f6896d599dcd1f1326ec5cd8f749e0a7d3c0ce1c8f9126bd4be985004319769de1e83cbca9301bf";
  char* badKey_4 = "0x04ffdb0fef8f8e3bd899250538bc3c651090aa5b579e9cefa38f6896d599dcd1f1326ec5cd8f749e0a7d3c0ce1c8f9126bd4be985004319769de1e83cbca930xyz";

  // generateAlias

  generateAliasCmp(pubKey_1);
  generateAliasCmp(pubKey_2);
  generateAliasCmp(pubKey_3);
  generateAliasCmp(pubKey_4);
  generateAliasCmp(pubKey_5);
  generateAliasCmp(badKey_1);
  generateAliasCmp(badKey_2);
  generateAliasCmp(badKey_3);
  generateAliasCmp(badKey_4);

  return 0;
}
