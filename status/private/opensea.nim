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

proc queryAssets*(owner: Address, offset: int, limit: int):
  Future[HttpFetchResult[seq[Asset]]] {.async.} =

  var content = ""
  let query = catch fmt"{owner}&offset={offset}&limit={limit}"
  if query.isErr: return err UrlBuildError
  let url = "https://api.opensea.io/api/v1/assets?owner=" & query.get
  try:
    let response = await fetch(HttpSessionRef.new(), parseUri(url))
    content = string.fromBytes(response.data)
  except CancelledError: return err HttpFetchError.CancelledError
  except HttpError: return err HttpFetchError.HttpError

  let container = Json.decode(content, AssetsContainer,
    allowUnknownFields = true)
  return ok container.assets