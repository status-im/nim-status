{.push raises: [Defect].}

import # std libs
  std/[json, options, sequtils, strformat, strutils, uri]

import # vendor libs
  chronos, chronos/apps/http/httpclient, json_serialization,
  stew/byteutils

import # status modules
  ./common, ../private/conversions

type
  AssetsContainer = object
    assets: seq[Asset]

  Asset* = object
    name*: Option[string]
    imageThumbnailUrl* {.serializedFieldName("image_thumbnail_url").}:
      Option[string]
    imageUrl* {.serializedFieldName("image_url").}: Option[string]
    contract* {.serializedFieldName("asset_contract").}: AssetContract
    collection*: Collection

  AssetContract* = object
    address*: Address

  Collection* = object
    name*: string

  OpenSeaError* = enum
    FetchError    = "opensea: error fetching assets from opensea"
    UrlBuildError = "opensea: error building query url"

  OpenSeaResult*[T] = Result[T, OpenSeaError]

proc queryAssets(owner: Address, offset: int, limit: int):
  Future[OpenSeaResult[seq[Asset]]] {.async.} =

  var content = ""
  let query = catch fmt"{owner}&offset={offset}&limit={limit}"
  if query.isErr: return err UrlBuildError
  let url = "https://api.opensea.io/api/v1/assets?owner=" & query.get
  try:
    let response = await fetch(HttpSessionRef.new(), parseUri(url))
    content = string.fromBytes(response.data)
  except CancelledError, HttpError:
    return err FetchError

  let container = Json.decode(content, AssetsContainer,
    allowUnknownFields = true)
  return ok container.assets

proc getOpenseaAssets*(self: StatusObject, owner: Address, limit: int = 50):
  Future[OpenSeaResult[seq[Asset]]] {.async.} =

  var offset = 0
  var assets: seq[Asset] = @[]
  while true:
    let tmpAssets = await queryAssets(owner, offset, limit)
    if tmpAssets.isErr: return err tmpAssets.error

    assets = concat(assets, tmpAssets.get)
    if len(tmpAssets.get()) < limit: break

    offset += limit

  return ok assets
