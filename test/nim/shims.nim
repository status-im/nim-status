from os import getEnv
{.passL: "-L" & getEnv("STATUSGO_LIBDIR")}
{.passL: "-lstatus"}
when defined(linux):
  {.passL: "-lcrypto"}
  {.passL: "-lssl"}
  {.passL: "-lpcre"}
when defined(macosx):
  {.passL: "bottles/openssl/lib/libcrypto.a"}
  {.passL: "bottles/openssl/lib/libssl.a"}
  {.passL: "bottles/pcre/lib/libpcre.a"}
  {.passL: "-framework CoreFoundation".}
  {.passL: "-framework CoreServices".}
  {.passL: "-framework IOKit".}
  {.passL: "-framework Security".}
  {.passL: "-headerpad_max_install_names".}

import ../../nim_status/lib/shim as nim_shim
import ../../nim_status/go/shim as go_shim
import base64
import nimPNG
import strutils

# hashMessage

proc hashCmp(str1: string, str2: string, testSame: bool): void =
  if testSame:
    assert nim_shim.hashMessage(str1) == go_shim.hashMessage(str2)
  else:
    assert nim_shim.hashMessage(str1) != go_shim.hashMessage(str2)

hashCmp("", "", true)
hashCmp("a", "a", true)
hashCmp("ab", "ab", true)
hashCmp("abc", "abc", true)
hashCmp("aBc", "aBc", true)
hashCmp("Abc", "abC", false)
hashCmp("0xffffff", "0xffffff", true)
hashCmp("0xFFFFFF", "0xffffff", true)
hashCmp("0xffffff", "0xFFFFFF", true)
hashCmp("0x" & "abc".toHex, "abc", true)
hashCmp("0x616263", "abc", true)
hashCmp("abc", "0x" & "abc".toHex, true)
hashCmp("abc", "0x616263", true)
hashCmp("0xabc", "0xabc", true)
hashCmp("0xaBc", "0xaBc", true)
hashCmp("0xAbc", "0xabC", false)
hashCmp("0xabcd", "0xabcd", true)
hashCmp("0xaBcd", "0xaBcd", true)
hashCmp("0xAbcd", "0xabcD", true)
hashCmp("0xverybadhex", "0xverybadhex", true)
hashCmp("0Xabcd", "0Xabcd", true)
hashCmp("0xabcd", "0Xabcd", false)
hashCmp("0Xabcd", "0xabcd", false)
assert nim_shim.hashMessage("0Xabcd") != nim_shim.hashMessage("0xabcd")
assert go_shim.hashMessage("0Xabcd") != go_shim.hashMessage("0xabcd")

const pubKey_01 = "0x0441ccda1563d69ac6b2e53718973c4e7280b4a5d8b3a09bb8bce9ebc5f082778243f1a04ec1f7995660482ca4b966ab0044566141ca48d7cdef8b7375cd5b7af5"
const pubKey_02 = "0x04ee10b0d66ccb9e3da3a74f73f880e829332f2a649e759d7c82f08b674507d498d7837279f209444092625b2be691e607c5dc3da1c198d63e430c9c7810516a8f"
const pubKey_03 = "0x046ffe9547ebceda7696ef5a67dc28e330b6fc3911eb6b1996c9622b2d7f0e8493c46fbd07ab591d62244e36c0d051863f86b1d656361d347a830c4239ef8877f5"
const pubKey_04 = "0x049bdc0016c51ec7b788db9ab0c63a1fbf3f873d2f3e3b85bf1cf034ab5370858ff31894017f56705de03dbaabf3f9811193fd5323376ec38a688cc306a5bf3ef7"
const pubKey_05 = "0x04ffdb0fef8f8e3bd899250538bc3c651090aa5b579e9cefa38f6896d599dcd1f1326ec5cd8f749e0a7d3c0ce1c8f9126bd4be985004319769de1e83cbca9301bf"
const pubKey_06 = "0x0488371505c57c1232fa821ba6963b1f250ac0fb72bf0519ada8f36a36cf8020c69d4a94432252d1e4d75997681381705c06b5fed61213d123cab092197e1f933a"
const pubKey_07 = "0x0406416d94cf8c8398966dca9eedb0cb485b18e2dd718e39f706be159d09b43896717be11e0610f62eca255526b832f9499c640ead09a38bd9ffde0a2dcf07313a"
const pubKey_08 = "0x040011a1ce61cb8ce22555442ef540f3b355a4d09d922e5a7e94c8c67265d3369a5ccbd0cce6861d8544ed561b25967d34a332ade61dc2c933655ecdee0cee484c"
const pubKey_09 = "0x0461717f5e30da90b0e5b024d7b92519226747fcbc0dc52d20b6f4f98f249f719eba1bb126bc1a925aec3186d3c3b4e74b42885a369e0ca34676848ef04605a180"
const pubKey_10 = "0x04cd43f8afaf4ccd3aeaa79547d259c2cd0e5db699ba7fa0bb3dd5b75b8805d1aed1cd12e69d29aeffe0bf77574c420339f913639fc1ac880ddf08b99e247bb358"
const pubKey_11 = "0x04335623d65400f122259e6221dda570e7c12e48711e8d22869a179c19665bfcdbf6a2a034fdcfd03a13bbaf5fa5ef5e607d224f4785a74a3e4256bc043e652097"
const pubKey_12 = "0x049263876e11372628c4d69dc51bd42fe6be5211128654d617e70c73f669d5192b672851d6f420efc8c5ebdade79c298c9b0dbd83c00084dbb8cb3c8ccc259f2f2"
const pubKey_13 = "0x0469932af292fd008fb6c4c74146a744c52815c3e3878d7a054a93693fbc4c26b48bc56267e01e9b12e5f4116d06df638ea74964bb9c7a86dc78e812fc768c9215"
const pubKey_14 = "0x0408ca2799cf3648324a9ef6f1e2103732b219e2326295a593ea9a91ac252e4368ce498c768f0bc42949c528b93f9498bba4349586e6f35faf6f13aaf24e5ad295"
const pubKey_15 = "0x0483c81ec1ae54f77c13eab798d526291d5664a26e8e91aaa8544008ed3c2960f9e243a45141fd56a7c5942e081945db993f372150853feb71a3d3d22d5e493401"
const pubKey_16 = "0x045463b67aba3b32f7fe8bfdea5fe28a53ee02fd0b5ce979122d40f4a8504f4fbbd101f276b9853eadffadab3baa2c94b852e75763498b67474d3333368b513fdc"
const pubKey_17 = "0x045350e6cac56e9d8a3528f5ebfba171d993de8b4e5c6134eb9b62b4c87f9cb910f85b9b1407f7da2607c330cd055557cd85957b18f0585fabbf83ff190f2da58d"
const pubKey_18 = "0x04ed045c2dc3472a8adc169797bc57fd582f39550746f161f215bac2e371bbcf78006d9a7239be8e5bed2d8ad3bed52c900bf10804712ca34e371f16d7d9dfd6d8"
const pubKey_19 = "0x0455f596c4d177bd59495bfd4fb94d27b0b5db8ca9043fb2241e753baa1824860b11c525f5570936aeaada7c1c6f318efe59039578e0b41a4e49962ed82b59ac3f"
const pubKey_20 = "0x04252dc037c147fbe39cb650d1f68fce098821ededa4f3785a446d428ec193374d65c3e468e2cbed3308be77e68bd243044cd2e6e27829123a30c612d10524d778"

const badKey_01 = "xyz"
const badKey_02 = "0x06abcd"
const badKey_03 = "0x06ffdb0fef8f8e3bd899250538bc3c651090aa5b579e9cefa38f6896d599dcd1f1326ec5cd8f749e0a7d3c0ce1c8f9126bd4be985004319769de1e83cbca9301bf"
const badKey_04 = "0x04ffdb0fef8f8e3bd899250538bc3c651090aa5b579e9cefa38f6896d599dcd1f1326ec5cd8f749e0a7d3c0ce1c8f9126bd4be985004319769de1e83cbca930xyz"

# generateAlias

proc generateAliasCmp(pubKey: string): void =
  assert nim_shim.generateAlias(pubKey) == go_shim.generateAlias(pubKey)

generateAliasCmp(pubKey_01)
generateAliasCmp(pubKey_02)
generateAliasCmp(pubKey_03)
generateAliasCmp(pubKey_04)
generateAliasCmp(pubKey_05)
generateAliasCmp(pubKey_06)
generateAliasCmp(pubKey_07)
generateAliasCmp(pubKey_08)
generateAliasCmp(pubKey_09)
generateAliasCmp(pubKey_10)
generateAliasCmp(pubKey_11)
generateAliasCmp(pubKey_12)
generateAliasCmp(pubKey_13)
generateAliasCmp(pubKey_14)
generateAliasCmp(pubKey_15)
generateAliasCmp(pubKey_16)
generateAliasCmp(pubKey_17)
generateAliasCmp(pubKey_18)
generateAliasCmp(pubKey_19)
generateAliasCmp(pubKey_20)
generateAliasCmp(badKey_01)
generateAliasCmp(badKey_02)
generateAliasCmp(badKey_03)
generateAliasCmp(badKey_04)

# identicon

# Here it's checked that the decoded PNGs are an exact match in terms of their
# pixel by pixel RGBA values represented as sequences of uint8 values. It's not
# possible to compare the base64 encoded strings directly since the PNG
# encodings are slightly different, which results in different strings.

proc identiconCmp(key: string): void =
  let go_b64 = go_shim.identicon(key)
  let nim_b64 = nim_shim.identicon(key)
  assert (go_b64 != "" and nim_b64 != "") or (go_b64 == "" and nim_b64 == "")
  if go_b64 == "" and nim_b64 == "":
    return
  let go_png_bytes = cast[seq[uint8]](decode(go_b64[22..^1]))
  let nim_png_bytes = cast[seq[uint8]](decode(nim_b64[22..^1]))
  let go_png = decodePNG32(go_png_bytes)
  let nim_png = decodePNG32(nim_png_bytes)
  assert go_png.get.data.len == nim_png.get.data.len
  var i = 0
  while i < nim_png.get.data.len:
    assert nim_png.get.data[i] == gopng.get.data[i]
    i += 1

identiconCmp(pubKey_01)
identiconCmp(pubKey_02)
identiconCmp(pubKey_03)
identiconCmp(pubKey_04)
identiconCmp(pubKey_05)
identiconCmp(pubKey_06)
identiconCmp(pubKey_07)
identiconCmp(pubKey_08)
identiconCmp(pubKey_09)
identiconCmp(pubKey_10)
identiconCmp(pubKey_11)
identiconCmp(pubKey_12)
identiconCmp(pubKey_13)
identiconCmp(pubKey_14)
identiconCmp(pubKey_15)
identiconCmp(pubKey_16)
identiconCmp(pubKey_17)
identiconCmp(pubKey_18)
identiconCmp(pubKey_19)
identiconCmp(pubKey_20)
identiconCmp(badKey_01)
identiconCmp(badKey_02)
identiconCmp(badKey_03)
identiconCmp(badKey_04)
