import # std libs
  std/unittest

import # status lib
  chronos, status/private/stickers

import # test modules
  ./test_helpers

procSuite "stickers":
  asyncTest "decodeContentHash":
    var
      hash = "e30101701220eab9a8ef4eac6c3e5836a3768d8e04935c10c67d9a700436a0e53199e9b64d29"
      cid = hash.decodeContentHash

    check:
      cid.isOk
      $cid.get == "Qme8vJtyrEHxABcSVGPF95PtozDgUyfr1xGjePmFdZgk9v"

    # testnet form #1
    hash = "e3017012205c531b83da9dd91529a4cf8ecd01cb62c399139e6f767e397d2f038b820c139f"
    cid = hash.decodeContentHash

    check:
      cid.isOk
      $cid.get == "QmUZ3icyt1wQpaPXk1RRvtioMu5LtyuHvjwvtYo4iu58nr"

    # testnet form #2
    hash = "e3011220c04c617170b1f5725070428c01280b4c19ae9083b7e6d71b7a0d2a1b5ae3ce30"
    cid = hash.decodeContentHash

    check:
      cid.isOk
      $cid.get == "QmbHJYDDW5CRdUfpLFRdJNCEDbZNYvAi7DAAfXrgheM1C3"

    # blank
    hash = ""
    cid = hash.decodeContentHash

    check:
      cid.isErr
      cid.error == HashValueError

    # wrong codec
    hash = "e4"
    cid = hash.decodeContentHash

    check:
      cid.isErr
      cid.error == InvalidMultiCodec

  asyncTest "decode edn":
    var
      edn = """{meta {:name      "Dogeth"
                 :author    "Mugen Flen"
                 :thumbnail "e3010170122094d3d16b41d6882dbc93e1690d945d0c00a2869cea94d0939f3ba3c0399685e6"
                 :preview   "e301017012204d6059ec0fab356add176ad2b2dd95656e50cb1e822232c00a30df04efa50378"
                 :stickers [{:hash "e3010170122094d3d16b41d6882dbc93e1690d945d0c00a2869cea94d0939f3ba3c0399685e6"}{:hash "e30101701220fcd853d7633d411a7002f286c8316336823c71114f52d672361300deb4760596"}{:hash "e3010170122058c8e08765a5d8a103f036ae65e6a3ba3f110fefb859965b213f92c293972bf5"}{:hash "e30101701220f7d8386783bf8691428389379bedaf94c79011a1fb1f17677c3d1582ddc8ab97"}{:hash "e3010170122040f0a7a6cfa8c281eeda40f6ba65667f07ab861e1c78f1374c738f1ca2161a31"}{:hash "e30101701220ac7cf793ac2baa36bd69dd10462b45831d85bbdf375f19a29a62dec78a9f8d3c"}{:hash "e3010170122070acac3d71c6243c5d100c2e6a53de7812fb42528236a0c3a4e2f4b2e61c6662"}{:hash "e301017012205aac43b08a22ddf3f40cacba2fa2f72251eb2c6bfb21fb46f8c0586a4655dc50"}{:hash "e3010170122092e871abca1681bbb46c9869fa6f449e85591accb16fac8130819f7ebbcf4305"}{:hash "e301017012204005f3279924ac12b1a396c20c7313f2356d1920d8ef3a2c60072e1223b8d4c8"}{:hash "e30101701220d655e130a998c54f3f68b23b52fe5a08b8f25f98b52270f9b438cd000bb2c719"}{:hash "e301017012207de9418dcb3a12feeb7c1d54e71ca45da8344c61a828ffab5285138da5a9b3a9"}{:hash "e3010170122073d50f10d4cebc4a816e4c6c86cd2ad28e03ba8b64279750113a2dcc893ba773"}{:hash "e30101701220adb1b6799d69d994a46eaedd2ba63a00b086355ae4ed0182c28173cd9df17797"}{:hash "e301017012205b7764a62aa6d7999ea1698d901c3048f42cafee61625584cb6f67ae14b36f70"}]}}"""
      decoded = edn.decode[:StickerPack]()

    check decoded.isOk
    let pack = decoded.get
    check:
      pack.author == "Mugen Flen"
      pack.name == "Dogeth"
      pack.preview == "e301017012204d6059ec0fab356add176ad2b2dd95656e50cb1e822232c00a30df04efa50378"
      pack.thumbnail == "e3010170122094d3d16b41d6882dbc93e1690d945d0c00a2869cea94d0939f3ba3c0399685e6"
      pack.stickers.len == 15
      pack.stickers[0].hash == "e3010170122094d3d16b41d6882dbc93e1690d945d0c00a2869cea94d0939f3ba3c0399685e6"
      pack.stickers[14].hash == "e301017012205b7764a62aa6d7999ea1698d901c3048f42cafee61625584cb6f67ae14b36f70"


