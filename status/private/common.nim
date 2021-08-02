import # std libs
  std/[hashes, strutils]

import # vendor libs
  stew/results

import # status modules
  ./util

export results

type
  StatusDefect* = object of Defect

  StatusError* = object of CatchableError

  ContentTopic* = object
    appName*: string
    appVersion*: string
    encoding*: string
    shortName*: string
    topicName*: string

  ContentTopicError* = enum
    invalid = "invalid content topic"

  DbError* = enum
    CloseFailure        = "db: failed to close database"
    DataAndTypeMismatch = "db: failed to deserialise data to supplied type"
    InitFailure         = "db: failed to initialize database"
    KeyError            = "db: could not key database with given key"
    MarshalFailure      = "db: failed to de/serialise db data to/from " &
                            "supplied type"
    MigrationError      = "db: error executing migrations"
    NotInitialized      = "db: not initialized, login required"
    OperationError      = "db: database operation error"
    QueryBuildError     = "db: invalid values used to build query"
    RecordNotFound      = "db: record not found"
    UnknownError        = "db: unknown error"

  DbResult*[T] = Result[T, DbError]

  HttpFetchError* = enum
    CancelledError          = "fetch: HTTP request cancelled"
    HttpError               = "fetch: error during HTTP request"
    ParseJsonResponseError  = "fetch: error parsing JSON response"
    UrlBuildError           = "fetch: error building URL"

  HttpFetchResult*[T] = Result[T, HttpFetchError]

  RpcError* = object
    code*: int
    message*: string

  web3ErrorKind* = enum
    ## Web3 Error Kinds
    web3Internal,
    web3Rpc

  Web3InternalError* = enum
    GetSettingsFailure      = "web3: failed to get web3 object, unable to get " &
                                "settings"
    InitFailureNetSettings  = "web3: failed to initialize web3 provider, " &
                                "network settings not available"
    InitFailureNetDisabled  = "web3: failed to initialize web3 provider, " &
                                "network not enabled"
    InitFailureBadUrlScheme = "web3: failed to initialize web3 provider, " &
                                "bad web3 URL scheme"
    NotFound                = "web3: initialized connection not found"
    ParseRpcResponseError   = "web3: failed to parse JSON RPC response"
    UnknownRpcError         = "web3: unknown RPC error"
    UserDbNotLoggedIn       = "web3: error getting user DB, not logged in"
    Web3ValueError          = "web3: web3 object cannot be null"

  Web3Error* = object
    case kind*: web3ErrorKind
    of web3Internal:
      internalError*: Web3InternalError
    of web3Rpc:
      rpcError*: RpcError

  Web3Result*[T] = Result[T, Web3Error]

const noTopic* = ContentTopic()

proc `$`*(t: ContentTopic): string =
  "/" & t.appName & "/" & t.appVersion & "/" & t.topicName & "/" & t.encoding

proc hash*(t: ContentTopic): Hash =
  hash $t

proc init*(T: type ContentTopic, t: string, s: string = ""):
  Result[ContentTopic, ContentTopicError] =

  var
    appName: string
    appVersion: string
    encoding: string
    shortName = s
    topicName: string

    topic = t.strip()

  if topic == "" or topic == "#":
    return err ContentTopicError.invalid

  else:
    let topicSplit = topic.split('/')

    if topic.startsWith('/') and topicSplit.len == 5:
      appName = topicSplit[1]
      appVersion = topicSplit[2]
      topicName = topicSplit[3]
      encoding = topicSplit[4]

    else:
      if topic.startsWith('#'): topic = topic[1..^1]

      appName = "waku"
      appVersion = "1"
      topicName = "0x" & ($keccak256.digest(topic))[0..7].toLowerAscii
      encoding = "rfc26"

      if shortName == "":
        shortName = "#" & topic
      elif not shortName.startsWith('#'):
        shortName = "#" & shortName

  ok(T(appName: appName, appVersion: appVersion, encoding: encoding,
       shortName: shortName, topicName: topicName))

proc isChat2*(t: ContentTopic): bool =
  t.appName == "toy-chat" and
  t.appVersion == "2" and
  t.encoding == "proto"

proc isWaku1*(t: ContentTopic): bool =
  t.appName == "waku" and
  t.appVersion == "1" and
  isHexString(t.topicName).get(false) and
  t.topicName.toLowerAscii == t.topicName and
  t.encoding == "rfc26"
