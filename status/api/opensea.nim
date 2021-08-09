{.push raises: [Defect].}

import # std libs
  std/[json, options, sequtils, strformat, strutils, uri]

import # vendor libs
  chronos, chronos/apps/http/httpclient, json_serialization,
  stew/[byteutils, result]

import # status modules
  ./common, ../private/conversions

type
  AssetsContainer = object
    assets: seq[Asset]

  Asset* = object
    name*: Option[string]
    imageThumbnailUrl* {.serializedFieldName("image_thumbnail_url").}: Option[string]
    imageUrl* {.serializedFieldName("image_url").}: Option[string]
    contract* {.serializedFieldName("asset_contract").}: AssetContract
    collection*: Collection

  AssetContract* = object
    address*: Address

  Collection* = object
    name*: string

  AssetsResult = Result[seq[Asset], string]

proc queryAssets(owner: Address, offset: int, limit: int): Future[AssetsResult] {.async.} =
  var content = ""
  let url = fmt("https://api.opensea.io/api/v1/assets?owner={owner}&offset={offset}&limit={limit}")
  try:
    let response = await fetch(HttpSessionRef.new(), parseUri(url))
    content = string.fromBytes(response.data)
  except CancelledError, HttpError:
    return AssetsResult.err "Error while fetching assets from opensea"

  let assets = Json.decode(content, AssetsContainer, allowUnknownFields = true).assets
  return AssetsResult.ok assets

proc getOpenseaAssets*(self: StatusObject, owner: Address, limit: int = 50): Future[AssetsResult] {.async.} =
  var offset = 0
  var assets: seq[Asset] = @[]
  while true:
    let tmpAssets = await queryAssets(owner, offset, limit)
    if tmpAssets.isErr: return tmpAssets

    assets = concat(assets, tmpAssets.get())
    if len(tmpAssets.get()) < limit: break

    offset += limit

  return AssetsResult.ok assets
