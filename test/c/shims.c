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

void identiconCmp(char* key, char* go_b64, char* nim_b64) {
  assert(strcmp(go_identicon(key), go_b64) == 0);
  assert(strcmp(nim_identicon(key), nim_b64) == 0);
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

  char* pubKey_01 = "0x0441ccda1563d69ac6b2e53718973c4e7280b4a5d8b3a09bb8bce9ebc5f082778243f1a04ec1f7995660482ca4b966ab0044566141ca48d7cdef8b7375cd5b7af5";
  char* pubKey_02 = "0x04ee10b0d66ccb9e3da3a74f73f880e829332f2a649e759d7c82f08b674507d498d7837279f209444092625b2be691e607c5dc3da1c198d63e430c9c7810516a8f";
  char* pubKey_03 = "0x046ffe9547ebceda7696ef5a67dc28e330b6fc3911eb6b1996c9622b2d7f0e8493c46fbd07ab591d62244e36c0d051863f86b1d656361d347a830c4239ef8877f5";
  char* pubKey_04 = "0x049bdc0016c51ec7b788db9ab0c63a1fbf3f873d2f3e3b85bf1cf034ab5370858ff31894017f56705de03dbaabf3f9811193fd5323376ec38a688cc306a5bf3ef7";
  char* pubKey_05 = "0x04ffdb0fef8f8e3bd899250538bc3c651090aa5b579e9cefa38f6896d599dcd1f1326ec5cd8f749e0a7d3c0ce1c8f9126bd4be985004319769de1e83cbca9301bf";
  char* pubKey_06 = "0x0488371505c57c1232fa821ba6963b1f250ac0fb72bf0519ada8f36a36cf8020c69d4a94432252d1e4d75997681381705c06b5fed61213d123cab092197e1f933a";
  char* pubKey_07 = "0x0406416d94cf8c8398966dca9eedb0cb485b18e2dd718e39f706be159d09b43896717be11e0610f62eca255526b832f9499c640ead09a38bd9ffde0a2dcf07313a";
  char* pubKey_08 = "0x040011a1ce61cb8ce22555442ef540f3b355a4d09d922e5a7e94c8c67265d3369a5ccbd0cce6861d8544ed561b25967d34a332ade61dc2c933655ecdee0cee484c";
  char* pubKey_09 = "0x0461717f5e30da90b0e5b024d7b92519226747fcbc0dc52d20b6f4f98f249f719eba1bb126bc1a925aec3186d3c3b4e74b42885a369e0ca34676848ef04605a180";
  char* pubKey_10 = "0x04cd43f8afaf4ccd3aeaa79547d259c2cd0e5db699ba7fa0bb3dd5b75b8805d1aed1cd12e69d29aeffe0bf77574c420339f913639fc1ac880ddf08b99e247bb358";
  char* pubKey_11 = "0x04335623d65400f122259e6221dda570e7c12e48711e8d22869a179c19665bfcdbf6a2a034fdcfd03a13bbaf5fa5ef5e607d224f4785a74a3e4256bc043e652097";
  char* pubKey_12 = "0x049263876e11372628c4d69dc51bd42fe6be5211128654d617e70c73f669d5192b672851d6f420efc8c5ebdade79c298c9b0dbd83c00084dbb8cb3c8ccc259f2f2";
  char* pubKey_13 = "0x0469932af292fd008fb6c4c74146a744c52815c3e3878d7a054a93693fbc4c26b48bc56267e01e9b12e5f4116d06df638ea74964bb9c7a86dc78e812fc768c9215";
  char* pubKey_14 = "0x0408ca2799cf3648324a9ef6f1e2103732b219e2326295a593ea9a91ac252e4368ce498c768f0bc42949c528b93f9498bba4349586e6f35faf6f13aaf24e5ad295";
  char* pubKey_15 = "0x0483c81ec1ae54f77c13eab798d526291d5664a26e8e91aaa8544008ed3c2960f9e243a45141fd56a7c5942e081945db993f372150853feb71a3d3d22d5e493401";
  char* pubKey_16 = "0x045463b67aba3b32f7fe8bfdea5fe28a53ee02fd0b5ce979122d40f4a8504f4fbbd101f276b9853eadffadab3baa2c94b852e75763498b67474d3333368b513fdc";
  char* pubKey_17 = "0x045350e6cac56e9d8a3528f5ebfba171d993de8b4e5c6134eb9b62b4c87f9cb910f85b9b1407f7da2607c330cd055557cd85957b18f0585fabbf83ff190f2da58d";
  char* pubKey_18 = "0x04ed045c2dc3472a8adc169797bc57fd582f39550746f161f215bac2e371bbcf78006d9a7239be8e5bed2d8ad3bed52c900bf10804712ca34e371f16d7d9dfd6d8";
  char* pubKey_19 = "0x0455f596c4d177bd59495bfd4fb94d27b0b5db8ca9043fb2241e753baa1824860b11c525f5570936aeaada7c1c6f318efe59039578e0b41a4e49962ed82b59ac3f";
  char* pubKey_20 = "0x04252dc037c147fbe39cb650d1f68fce098821ededa4f3785a446d428ec193374d65c3e468e2cbed3308be77e68bd243044cd2e6e27829123a30c612d10524d778";

  char* badKey_01 = "xyz";
  char* badKey_02 = "0x06abcd";
  char* badKey_03 = "0x06ffdb0fef8f8e3bd899250538bc3c651090aa5b579e9cefa38f6896d599dcd1f1326ec5cd8f749e0a7d3c0ce1c8f9126bd4be985004319769de1e83cbca9301bf";
  char* badKey_04 = "0x04ffdb0fef8f8e3bd899250538bc3c651090aa5b579e9cefa38f6896d599dcd1f1326ec5cd8f749e0a7d3c0ce1c8f9126bd4be985004319769de1e83cbca930xyz";

  // generateAlias

  generateAliasCmp(pubKey_01);
  generateAliasCmp(pubKey_02);
  generateAliasCmp(pubKey_03);
  generateAliasCmp(pubKey_04);
  generateAliasCmp(pubKey_05);
  generateAliasCmp(pubKey_06);
  generateAliasCmp(pubKey_07);
  generateAliasCmp(pubKey_08);
  generateAliasCmp(pubKey_09);
  generateAliasCmp(pubKey_10);
  generateAliasCmp(pubKey_11);
  generateAliasCmp(pubKey_12);
  generateAliasCmp(pubKey_13);
  generateAliasCmp(pubKey_14);
  generateAliasCmp(pubKey_15);
  generateAliasCmp(pubKey_16);
  generateAliasCmp(pubKey_17);
  generateAliasCmp(pubKey_18);
  generateAliasCmp(pubKey_19);
  generateAliasCmp(pubKey_20);
  generateAliasCmp(badKey_01);
  generateAliasCmp(badKey_02);
  generateAliasCmp(badKey_03);
  generateAliasCmp(badKey_04);

  // identicon

  // The real test is performed in ../nim/shims.nim, which compares the decoded
  // PNGs pixel by pixel since the encodings are slightly different, which
  // results in different base64 encoded strings. Here it's simply checked that
  // the expected base64 values are returned.

  char* go_b64_01  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAk0lEQVR4nOzYwQmEMBQG4exiL1ZjN5ZhN1ZjNXrxaCCQBIaf+Y4iwvAgvPgvIQyhMYTGEBpDaGJClt4PHOd1fz3ft/U34v1WMRMxhMYQGkNoDKExhKZ5v6ntSLO17mAxEzGExhCarltZGXiaeUN8GUJjCE33qVUz6/9VTcxEDKExRJPETMQQGkNoDKExhOYJAAD//7VPFGKMHGOVAAAAAElFTkSuQmCC";
  char* nim_b64_01 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAZ0lEQVR4Ae3UMQ6AIAxAUeP5uQ2n4TQ6ukjCAFrre0k3Bj5N2AAALqW2425mnR+1v/0QswiJRkg0QqIREo2Qzyq1HW/M6P3SbERINELSefp36kmzESHRCPmNVb9TT5qNCIlGCADAOifdFswjU3SRrgAAAABJRU5ErkJggg==";
  char* go_b64_02  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAk0lEQVR4nOzYwQnCQBQGYRV78WxvKSO95ZxqknvIwsLbDcPPfEcRYfjhsfh5hTCExhAaQ2gMoYkJ+VZ/YN234+7z5fd/j/h+r5hFDKExhKb7arWuzSjVaxaziCE0htCU31ots6/cVcwihtAYokliFjGExhCax99a1f+vWmIWMYTGEE0Ss4ghNIbQGEJjCM0ZAAD//0Z8Fs/Oqls7AAAAAElFTkSuQmCC";
  char* nim_b64_02 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAaUlEQVR4Ae3VQQqAIBAF0IiO791cdxpbtjEoGmmS92B2onyF7wIAcCp7bb2JWn/X+vVFRBEkG0F+66ptolrrbZtN8yKCZCNINtuojZ80ToRpXkSQbAQBIKWy19abUedN848Iko0gAADjHHD8ib7huqEAAAAAAElFTkSuQmCC";
  char* go_b64_03  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAlklEQVR4nOzX0QmDUBAF0SSklxSTdlJG2rEYq9F/UXiyK4yXOf+RDAsX3usRwhAaQ2gMoTGEJibkXf3Af5qXjj/y+36eld/HXMQQGkNohlfraJ2qa9P1/ZiLGEJjCE3L4uy5euW2Yi5iCI0hNOUF8YXYzBAaQ2iGl6Jrnc7yhXhXhtDEhMSIuYghNIbQGEJjCM0aAAD//5bkGGRhA5HWAAAAAElFTkSuQmCC";
  char* nim_b64_03 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAbElEQVR4Ae3UwQmAMAxAUXF+13EYp9GjIHgQE0zje9Br6W8gEwDAaVm3PeK8fcf89UdEEVKNkGFlbZuo+9tMREg1Qn4je8tdtZmIkGqEtHO3nZ6et+9oMxEh1QgZVtR2ytpmbSYipBohAAB5DmWTBHaeBJQGAAAAAElFTkSuQmCC";
  char* go_b64_04  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAg0lEQVR4nOzWwQmAMBQEURV7sRFLsgxLshGr0QZyCCQfhmXeUSQwLIRsSwhDaAyhMYTGEBpDaAyhMYQmJmQfPeB+3q/1/TqPdcb/vWIWMYTGEJrum6Lqtpl1fswihtAYQoN5a42KWcQQGkNoDKExhMYQFYlZxBAaQ2gMoTGE5g8AAP//St0XhgBe61AAAAAASUVORK5CYII=";
  char* nim_b64_04 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAYElEQVR4Ae3UUQqAIBBFUWn9LamNtJr6j4KCkZ5yDvgnA1dhGgAAwKjWbT/uTtX9t5a/H6KKkDRChtVr21TNn+ZHhKQRMqynrfJ121TNuZrmR4SkEZJGSBohaYQAAPRzAp/ZliudjXNFAAAAAElFTkSuQmCC";
  char* go_b64_05  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAnUlEQVR4nOzY0QmDMBRG4bZ0l+7TWRzDWdzHafQ9EDHcCIef870bPFy4RD+vEIbQGEJjCI0hNDEh3+oB67YfM15k+f/eledjJmIIjSE0pU1xpbfNqtupJ2YihtAYQnP7rjV6p+ptp1nntGImYgiNITTlL8TRu9OsbdaKmYghNIbQYP5rVcVMxBAaQ/SQmIkYQmMIjSE0htCcAQAA///dlxhq1Y4r+AAAAABJRU5ErkJggg==";
  char* nim_b64_05 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAcElEQVR4Ae3UwQmAMAxAURHHdxb3cRo9CoIHSYppfQ96DX4DmQAALuu2Hxkv+h3z1z8ii5BqhPxGq+v0ZJiNCKlGSLeertDb65Q1526YjQipRki3olel9fxhNiKkGiHVLNEBmZcrYpiNCKlGCABAOydUs7uBcVGURQAAAABJRU5ErkJggg==";
  char* go_b64_06  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAmElEQVR4nOzYwQmFMBAA0f/FXizA1izD1izAavSSk0SIJAvDMu8oEhgWFpLpl4QhNIbQGEJjCE2akLn3gP04r9r3bV3+I/5vlWYihtAYQtO8KaK2zajz00zEEBpDaIZsnJroLfeUZiKG0BhC071B3rbTV94QC0NoDKFpfteKfr/yhlgYQmOIgqSZiCE0htAYQmMIzR0AAP//lSkkZN3k4WYAAAAASUVORK5CYII=";
  char* nim_b64_06 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAcElEQVR4Ae3UUQqEMAxAQfH8e7U9wJ5m/RSKgsUG0zgD/SvFZyALAMDu8/39j86o+1etT/+IUYRkI2RaUdtm1PtlJiIkGyGvEb3lWmUmIiQbIeWcbafec/c7ykxESDZCptW7baLvt8pMREg2QgAA4mwbaNLVS2NWgwAAAABJRU5ErkJggg==";
  char* go_b64_07  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAo0lEQVR4nOzXwQkCMRBGYRV7sQMrswwrswOr0ZOXQCTDbODx877zEngMDLOXUwhDaAyhMYTGEJqYkOvqh8/X+1N5+HG/nXe+M4qZiCE0htAsbYR/qltoZnU7zcRMxBAaQ2jat1b1pjrq+1HMRAyhMYRmeWvNVG+to26zUcxEDKExhKa9tbp/dj/dbRYzEUNoDNEmMRMxhMYQGkNoDKH5BgAA///jZyLG3MhBiAAAAABJRU5ErkJggg==";
  char* nim_b64_07 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAfElEQVR4Ae3U0QmAMAxF0Sru4gZO5hhO5gZOo/8FwZiGPuM90L9SuA2kAACAP9r247Sc6HdqY+8PaoUQNYSkY91C3u10J81ECFFDyGdZt030/VqaiRCihhA1k/cBy2Z5c/+pNBMhRA0hatwh6zIPLU73EBWEqCEEAAAgzgW2GNQhQvtAFwAAAABJRU5ErkJggg==";
  char* go_b64_08  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAlElEQVR4nOzYwQmDQBBG4SSkl9STXlJGerEeq9G7KIzsDjx+3neeg4+BYfH1CGEIjSE0htAYQhMT8q4O/pd16/2Uc7/v51mZi9mIITSGqEnMRgyhMYRm+K119Rbqnj+K2YghNIbQlK/WXdVrM0vMRgyhMYRm+LLM+t81euViNmIIjSFqErMRQ2gMoTGExhCaPQAA///EKxVT1czzbgAAAABJRU5ErkJggg==";
  char* nim_b64_08 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAcUlEQVR4Ae3VwQ2DMAxAUVp1l87TXTpGdsk8mSa9VxyQIIll3pN8Q8gfH9gAgDsqtfUVc3S/5+oPdBUh0QgBYIpSW9+bVc//S/MfERKNkGheo178/bwfM0PSXERINELSKbX1K+bsHmkuIiQaIQAA4/wAYsvMAPtP9jAAAAAASUVORK5CYII=";
  char* go_b64_09  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAmUlEQVR4nOzXwQkCQRAFURVz0QANwwA1Gr0vOzBDT0PxqXeURSwaPu7tEsIQGkNoDKExhCYm5D774Pf9+Z19/ng9rzt+SPX7Yy5iCI0hNOXFGa3Nqur6xVzEEBpDaNr+a3U/fxRzEUNoDKGZXq2RXetUFXMRQ2gMoSmv1uqbXdeaxVzEEBpD1CTmIobQGEJjCI0hNP8AAAD//8jNJGr/ACdeAAAAAElFTkSuQmCC";
  char* nim_b64_09 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAbUlEQVR4Ae3UQQqAMAwEQPH9PlBfo3exB2mDaZyB3ErpNrALAPBHx7afT5Pl/vXrDxpFkGwEKafVNm+n9x1lNiJINoJM623bRJ+/K7MRQbIRZFqtVhnVTlpLkKQEmVZvq0TfX2YjgmQjCABAnAv83Q/yHiavrwAAAABJRU5ErkJggg==";
  char* go_b64_10  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAlUlEQVR4nOzXwQmEQAxA0d1le7ERS7IMS7IRq9G7GInMiJ/w31Fy+QTC+PsUYQiNITSG0BhCYwiNITSG0JQJ+WcH52Xdzr5P4/B9Y/6ozEYMoTGEJn21ItG16TWfVWYjhtAYQpN6x1zpdYWyb6pImY0YQmMITfPVirT+8d1VZiOG0Biih5TZiCE0htAYQmMIzR4AAP//6dUapcA17BkAAAAASUVORK5CYII=";
  char* nim_b64_10 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAZ0lEQVR4Ae3U0QmAMAxAQRHHdyQXcRrFX1FQ29IQ76B/pfgMZAAAAIhuXtbt6vS6fzb2/kG1CIlGSDRT6QNvNsuX+0+lmYiQaISkc2yhGqf0O9JMREg0Qn6j1Xa6k2YiQqIRAgDQzg4qkomtDuNHlgAAAABJRU5ErkJggg==";
  char* go_b64_11  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAk0lEQVR4nOzY0QmEMBAG4TuxF8uwKcuwKcuwGm3AQCCuDD/zPYqIw8ISnX4hDKExhMYQGkNoYkLm3hv347yerm/r8n/jRUafHzMRQ2gMoeneWi2tbfO1mIkYQmMIzfDWqj5r9YqZiCE0hqhIzEQMoTGEpuwLsXUGq/o/FjMRQ2gMUZGYiRhCYwiNITSG0NwBAAD//4h2F47hoXg5AAAAAElFTkSuQmCC";
  char* nim_b64_11 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAbklEQVR4Ae3V4QmFIBiG0e6lXRqjpRqjpRrDaWqBfgQavtg58P0T4VHQCQD4ov0o592k7P/vfUCtCEkjJM1cu0HLl6vGMDciJI2QNNUh27r8Wkz3kBRC0ggBoKv9KOfdtFr/1DD/iJA0QgAA3nMBjkheMqlJ9soAAAAASUVORK5CYII=";
  char* go_b64_12  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAjElEQVR4nOzXUQmAQBAGYRW72MgkxjCJjUyjBTzYQw6Gn/me98Fh4ViXKYQhNIbQGEJjCI0hNIbQGEITE7JWB6/7fMZ+yrd9O+bKXMxGDKExhMYQGkNoDKEp31otrVuodZv1zlfFbMQQGkNofr9ava/NqD/NmI0YQmOIBonZiCE0htAYQmMIzRsAAP//eckShReeRAYAAAAASUVORK5CYII=";
  char* nim_b64_12 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAZElEQVR4Ae3UTQrDIBRG0VK6fFfijlyNnYcMzB9+kXPA2SPk+sAPAABAutpKn3FG/+87+4LuIiSNkDRC0ghJI+S1ait978ya31pmI0LSCEnzu/qBIy/LmflRy2xESBohAADP+QMbOZjrEGpysgAAAABJRU5ErkJggg==";
  char* go_b64_13  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAg0lEQVR4nOzWUQmAQBAGYRW7mMkexrCHmUyjBRSUvYPhZ75HkeOGheWmIYQhNIbQGEJjCI0hNIbQGEJjCI0hNIbQxITMX3/cz+N6+r4t69jiItXzYyZiCI0hNOWN87Zt/qpuv5iJGEJjCI1vLRpDaAxRJzETMYTGEBpDaAyhuQMAAP//VwQUZomgpuQAAAAASUVORK5CYII=";
  char* nim_b64_13 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAVklEQVR4Ae3U0QnAMAgFwND5u0dn6jTtAu1HiCFG7sBf8SnYAAAAAIh03tfzVVn6H6sXFEWQbAQp5+/b9NboHGUuIkg2gmxr1reJ6l/mIoJkIwgAwDwvwQ9/7bhniAEAAAAASUVORK5CYII=";
  char* go_b64_14  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAiElEQVR4nOzYsQmEUBQF0V2xF3NrswxrM7caTQz9oHwfDJc5oYgwvOTi8AthCI0hNIbQGEITEzL2fmDd9uPu+TJP/y/efyrmIobQGKIiMRcxhMYQmu6t1VK1qVpiLmIIjSE0htAYQmMITffuaW2qt/yvdTGExhAVibmIITSG0BhCYwjNGQAA///dkRBklltN8wAAAABJRU5ErkJggg==";
  char* nim_b64_14 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAXklEQVR4Ae3VMQrAIBQFQcn5PZu9pzFlGotAlDxkBn4n6GphAQB41NbHbFatf+v6+yJWEZJGCACRautjNrv2O+YfEZJGSBohaYSkEXKc2vpYMV/PccyLCEkjBABgnxuynHMz+ACdOwAAAABJRU5ErkJggg==";
  char* go_b64_15  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAkUlEQVR4nOzW0QmAMAwAURV3cQFHcwxHcwGn0X+pUGkDZ7j3KSIegZBpSMIQGkNoDKExhCZNyFz74n4eV+n5tqxjjx9p/X6aiRhCYwhNl41TEr3lntJMxBAaQ2iqN8jbFormrfVXhtCkCWm+e77eVFE3WJqJGEJjCI0hNIbQGKIgaSZiCI0hNIbQGEJzBwAA//+xuRhi5JHvewAAAABJRU5ErkJggg==";
  char* nim_b64_15 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAaElEQVR4Ae3UwQmAMBBFQbF+S7MBq9G7GFA0+F1nINeQl4UdAIA/mpZ5PTop949vf9BThKQR8hu9t9xemYkISSPks1pbqPc5+74yExGSRkg5V7fN3e3UUmYiQtIISSMkjZA0QgAA+tkAqZi/dScnT28AAAAASUVORK5CYII=";
  char* go_b64_16  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAlElEQVR4nOzXwQmDQBBG4SSkl7SWAizDAmzNavQuLq6M4uPnfUeZy2NgcD+vEIbQGEJjCI0hNDEh397BcZ6Wve/D7/9+Yn4rZiOG0BhC0321Wq66TlUxGzGExhCa8tXq/Rc6mq9es5iNGEJjCE35arVUX3xnxWzEEBpDdJOYjRhCYwiNITSG0BhCYwiNITRrAAAA//+mxBxrInMMoAAAAABJRU5ErkJggg==";
  char* nim_b64_16 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAYUlEQVR4Ae3UwQmAMBREQbF+C7A1q9G76Ml8sokz4E0CL4FdAIA/2o79fPp6/X+39r6gVoSkETKst1VptU5WS0goIcP6uirV50/zIkLSCElTFlK9cl4knZA004QAAAD0cgEiELM7LkPipAAAAABJRU5ErkJggg==";
  char* go_b64_17  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAgklEQVR4nOzXsQmAQBAFURV7sTZzyzC3NqvRXDxZA3H4zAuPTYaFhRu6EIbQGEJjCI0hNIbQGEJjCE1MyFgdXLf9uHtf5qn/Y/4qZiOG0BhCU7oIT1rX5q3qdWqJ2YghNIbQGEJjCI0hNP4QaQyhMUQfidmIITSG0BhCYwjNGQAA///omBxmOuGhKAAAAABJRU5ErkJggg==";
  char* nim_b64_17 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAX0lEQVR4Ae3UsQqAIBSG0ej53X02n8Z2qSEq/JNz4G538FNwAwAASFdq62cza3+0z76gtwhJI2Q5V7/N3Xl6jmVeREgaIWmEpBGSRshvldr62czaHy3zIkLSCAEA+M4B64+hHeAhkrsAAAAASUVORK5CYII=";
  char* go_b64_18  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAlElEQVR4nOzW0QmEMBAG4TuxF/uwJsuwJvuwGn0XhYQkMPzM93iEw2Fh2ekXwhAaQ2gMoTGEJiZkLn24n8f19vu2rP8eH9L6/zETMYTGEJrirVVr9JZ7ipmIITSG0DRvra/t1Ot9qZiJGEJjCE3z3VN7U426wWImYgiNIRokZiKG0BhCYwiNITSG0BhCYwjNHQAA///YzhqsKhq2mAAAAABJRU5ErkJggg==";
  char* nim_b64_18 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAZklEQVR4Ae3UwQmAMBBFQRHLtyb7sBpFvOagaPCzzkBuIfCysAMA8Efzumytk/L++PUHvUVIGiFpuoX03nImkk5ImjIh09MH7m6iXpurzESEpBFSzrGFWuet+1eVmYiQNEIAAAA47RhjZG+9Rh+XAAAAAElFTkSuQmCC";
  char* go_b64_19  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAiklEQVR4nOzYsQmAQBAFURV7MbE8y7A8E6vRBhRXjoPhMy++wGGTj9MQwhAaQ2gMoTGEJiZkrj7cj/Pq+ynPtnUZK+9iLmIIjSE0htAYQmMITXlr/fW2kXpttpiLGEJjCI0hNIbQGELTvLWq/52+3rdusJiLGEJjiDqJuYghNIbQGEJjCM0dAAD//xTSDTE4YY+HAAAAAElFTkSuQmCC";
  char* nim_b64_19 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAa0lEQVR4Ae3RsRECIQBFQbGZSyiPMizPxGq0AQJnxOPD7c78jIAHNwDgih7P13vGvr3fffYDjSIkjZA0QtIISSMkzd9CWj1Kb8uFnE1IGiFphKQRkkZImp9DWj1Kb6PO+5FVCUmzTQgAsJMPXdlu2xSxgz0AAAAASUVORK5CYII=";
  char* go_b64_20  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAkklEQVR4nOzYwQmFMBAA0f/FXqzMDizDDqzMavTiSQxs1OCwzDuGvQwLIaT7JWEIjSE0htAYQpMmpI8OLuu8XZ2Pw/T/Yv4szUYMoTGEJnxrlZRum7fmo9JsxBAaQ2hC75g7nr6daqXZiCE0htAYQmMIjSE0zf61avmvdTCExhA1kmYjhtAYQmMIjSE0ewAAAP//pjweZgztcigAAAAASUVORK5CYII=";
  char* nim_b64_20 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAcklEQVR4Ae3USwrAIAxFUSldvjtwZa7G0qlk0I+SZ7wHMguWW8EEAAB2VGpu1njt9w7vHzQKIWoIUXP+PeDNy/Jl/6kwN0KIGkK2cb9O1sz6XpgbIUQNIWoIUUOIGkKWVWpu1njt98LcCCFqCAEAAJjnAv4FhA0qj5T5AAAAAElFTkSuQmCC";
  char* go_b64_21  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAiklEQVR4nOzUwQmAMBAFURV70QItwwK1Gr0HQnYPgWGZdw6BYeFvSxGG0BhCYwiNITSG0BhCYwiNITSG0BhCUyZkjz683+fLfHwd5zrzn1aZixhCYwhNeLV6oqsyep9ds1aZixhCYwhNanEyeiuUXbmoMhcxhMYQTVLmIobQGEJjCI0hNH8AAAD//yusESocCiZuAAAAAElFTkSuQmCC";
  char* nim_b64_21 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAUklEQVR4Ae3UQQqAMAxFQfH8HlBPo/vuxH5M2xnoNvAayAYAAABAT8d13m9eek5r//uDehFSjZBhfb0q6fnTbERINUKWkb5yrWk2IqQaIQAAOQ/Nr4f3HldRAgAAAABJRU5ErkJggg==";
  char* go_b64_22  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAh0lEQVR4nOzYwQmEQBAF0V0xFzMzAsMwAjMzGr0LAz2HhuJT7ywDxb80Lr8QhtAYQmMIjSE0MSFr9cPzvp6Zh49t/3e+8xWziCE0hqhJzCKG0BhCU761Rka30+ytVb2pRmIWMYTGEDWJWcQQGkNo/K9FYwiNIWoSs4ghNIbQGEJjCM0bAAD//yatGGXKTxImAAAAAElFTkSuQmCC";
  char* nim_b64_22 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAW0lEQVR4Ae3VMQrAIAxA0dLze4LcLKexu3RoQavY9yCbBL5LDgDgj0pGfTOj97TO2R/Ui5DVCAFgqpJR76bX+6e2uSNCViMEgE+UjPpmRu9pbXNHhKxGCADAOBedWbOn+OO/yQAAAABJRU5ErkJggg==";
  char* go_b64_23  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAkklEQVR4nOzYwQmAMBAFURV7sTfPluHZ3qxGGzCghJXhM+8oEhkWwuI0hDCExhAaQ2gMoYkJmasO3o/zenq+rctY8b2YiRhCYwjN61ur+hbqPT9mIobQGEJTtmtV7VQtMRMxhMYQmu5b6+uO1Hq/V8xEDKExhOb3/1pVYiZiCI0hKhIzEUNoDKExhMYQmjsAAP//EQkXZy2G+AYAAAAASUVORK5CYII=";
  char* nim_b64_23 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAeklEQVR4Ae3UQQqAIBRF0Qr30t4atwzH7s3V2FyCEnr1+twDzuTL5YMTAADAtVxqOzuq95avgwkhxFyYkNtGfyH1/V6YjRDihhA3STV439b5zZAwGyHEDSG/lUttI0c9pxdmI4S4IcRNUg0e+XGeEGYjhLghBAAAQOcAqCSTGzD+2xcAAAAASUVORK5CYII=";
  char* go_b64_24  = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAnUlEQVR4nOzYwQmEMBBA0d1le7E275bh3dqsRi+exEjCJPAZ/juKBD4DQ/T3ScIQGkNoDKExhCZNyD96wLrtx9PzZZ6+Pd6vlWYihtAYQhPeWiWl7TRKmokYQmMITeh+82bUnaokzUQMoTGEJrxBet2p/EK8GEJjCE31pmjdTq3/tVrPuUszEUNoDNEgaSZiCI0hNIbQGEJzBgAA///luRtfuq1hLQAAAABJRU5ErkJggg==";
  char* nim_b64_24 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAb0lEQVR4Ae3UMQqAMAxAUfH87p7N0+joYkBpizG+B9kc+g1kAgA4Leu2X02v7++a3/4RvQjJRkg50RV6Oq3vKLMRIdkI+Y1R1ylSZiNCshFSTnSdnk7rO8psREg2Qj6r1xUadc3KbERINkIAAMY5AGw76K1Ynwl+AAAAAElFTkSuQmCC";

  identiconCmp(pubKey_01, go_b64_01, nim_b64_01);
  identiconCmp(pubKey_02, go_b64_02, nim_b64_02);
  identiconCmp(pubKey_03, go_b64_03, nim_b64_03);
  identiconCmp(pubKey_04, go_b64_04, nim_b64_04);
  identiconCmp(pubKey_05, go_b64_05, nim_b64_05);
  identiconCmp(pubKey_06, go_b64_06, nim_b64_06);
  identiconCmp(pubKey_07, go_b64_07, nim_b64_07);
  identiconCmp(pubKey_08, go_b64_08, nim_b64_08);
  identiconCmp(pubKey_09, go_b64_09, nim_b64_09);
  identiconCmp(pubKey_10, go_b64_10, nim_b64_10);
  identiconCmp(pubKey_11, go_b64_11, nim_b64_11);
  identiconCmp(pubKey_12, go_b64_12, nim_b64_12);
  identiconCmp(pubKey_13, go_b64_13, nim_b64_13);
  identiconCmp(pubKey_14, go_b64_14, nim_b64_14);
  identiconCmp(pubKey_15, go_b64_15, nim_b64_15);
  identiconCmp(pubKey_16, go_b64_16, nim_b64_16);
  identiconCmp(pubKey_17, go_b64_17, nim_b64_17);
  identiconCmp(pubKey_18, go_b64_18, nim_b64_18);
  identiconCmp(pubKey_19, go_b64_19, nim_b64_19);
  identiconCmp(pubKey_20, go_b64_20, nim_b64_20);
  identiconCmp(badKey_01, go_b64_21, nim_b64_21);
  identiconCmp(badKey_02, go_b64_22, nim_b64_22);
  identiconCmp(badKey_03, go_b64_23, nim_b64_23);
  identiconCmp(badKey_04, go_b64_24, nim_b64_24);

  return 0;
}
