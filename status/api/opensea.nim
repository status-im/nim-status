{.push raises: [Defect].}

import # std libs
  std/[json, options, sequtils, strutils, uri]

import # vendor libs
  chronos, chronos/apps/http/httpclient, json_serialization

import # status modules
  ./common, ../private/[conversions, opensea]

export Asset

type
  OpenSeaError* = enum
    FetchError    = "opensea: error fetching assets from opensea"
    UrlBuildError = "opensea: error building query url"

  OpenSeaResult*[T] = Result[T, OpenSeaError]

proc getOpenseaAssets*(self: StatusObject, owner: Address, limit: int = 50):
  Future[OpenSeaResult[seq[Asset]]] {.async.} =

  var offset = 0
  var assets: seq[Asset] = @[]
  while true:
    let tmpAssets = await queryAssets(owner, offset, limit)
    if tmpAssets.isErr: return err FetchError

    assets = concat(assets, tmpAssets.get)
    if len(tmpAssets.get()) < limit: break

    offset += limit

  return ok assets
