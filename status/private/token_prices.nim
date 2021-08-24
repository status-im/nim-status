{.push raises: [Defect].}

import # std libs
  std/[json, strformat, tables, uri]

import # vendor libs
  chronos/apps/http/httpclient,
  json_serialization,
  json_serialization/[reader, writer],
  sqlcipher, stew/byteutils, web3/ethtypes

import # status modules
  ./common, ./conversions, ./util

type
  PriceEntry* = ref object
    fromSym*: string
    toSym*: string
    price*: float
    lastDay*: float

  PriceMap* = TableRef[string, ToPriceMap]

  ToPriceMap* = TableRef[string, PriceEntry]

const
  API_URL = "https://min-api.cryptocompare.com/data"
  STATUS_IDENTIFIER = "extraParams=Status.im"
  FIAT_CURRENCIES* = @["USD", "EUR"]

proc `$`*(p: PriceEntry): string {.raises: [].} =
  try:
    fmt"token={p.fromSym}, fiat={p.toSym}, price={p.price}"
  except:
    "Empty PriceEntry"

proc genPriceUrl(fsyms: seq[string], tsyms: seq[string]): string
  {.raises: [].} =

  return API_URL &
    "/pricemultifull?fsyms=" & join(fsyms, ",") &
    "&tsyms=" & join(tsyms, ",") &
    "&" & STATUS_IDENTIFIER

proc parseResponse(resp: string, isMainnet: bool): HttpFetchResult[PriceMap] =
  var fromMap = newTable[string, ToPriceMap]()
  try:
    let raw = ?(catchEx parseJson(resp)["RAW"]).mapErrTo(ParseJsonResponseError)
    for `from`, entries in raw.getFields():
      let fromSym = if isMainnet: `from` else: "ETH"
      var toMap = newTable[string, PriceEntry]()
      for toSym, entry in entries.getFields():
        toMap[toSym] = PriceEntry(
          fromSym: fromSym,
          toSym: toSym,
          price: entry["PRICE"].getFloat,
          lastDay: entry["OPEN24HOUR"].getFloat
        )

      fromMap[fromSym] = toMap
  except KeyError:
    return err ParseJsonResponseError

  ok(fromMap)

proc updatePrices*(fromSyms: seq[string], toSyms: seq[string], isMainnet: bool):
  Future[HttpFetchResult[PriceMap]] {.async.} =

  try:
    let
      url = genPriceUrl(fromSyms, toSyms)
      resp = await fetch(HttpSessionRef.new(), parseUri(url))

    return parseResponse(string.fromBytes(resp.data), true)
  except CancelledError: return err HttpFetchError.CancelledError
  except HttpError: return err HttpFetchError.HttpError