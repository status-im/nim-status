import
  stew/results

export results

type
  StatusDefect* = object of Defect

  StatusError* = object of CatchableError

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
