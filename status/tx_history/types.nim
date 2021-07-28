import json_serialization
import sqlcipher
import tables

type 
  BlockRange* = array[2, int]
  BlockSeq* = seq[int]
  Address* = string
  TxType* = enum
    eth, erc20

  TransferMap* = Table[string, Transfer]

  TxDbData* = ref object
    info*: TransferInfo
    txToData* : TransferMap

  TransferInfoType* {.pure.} = enum
    Address = "address",
    Balance = "balance",
    BlockNumber = "blockNumber"
    TxCount = "txCount",

  TransferInfoCol* {.pure.} = enum
    Address = "address",
    Balance = "balance",
    BlockNumber = "block_number"
    TxCount = "tx_count",

  TransferInfo* {.dbTableName("tx_history_info").} = object
    address* {.serializedFieldName($TransferInfoType.Address), dbColumnName($TransferInfoCol.Address)}: string
    balance* {.serializedFieldName($TransferInfoType.Balance), dbColumnName($TransferInfoCol.Balance)}: int
    blockNumber* {.serializedFieldName($TransferInfoType.BlockNumber), dbColumnName($TransferInfoCol.BlockNumber)}: int
    txCount* {.serializedFieldName($TransferInfoType.TxCount), dbColumnName($TransferInfoCol.TxCount)}: int

  TransferType* {.pure.} = enum
    Id = "id",
    TxType = "txType",
    Address = "address",
    BlockNumber = "blockNumber",
    BlockHash = "blockHash",
    Timestamp = "timestamp",
    GasPrice = "gasPrice",
    GasLimit = "gasLimit",
    GasUsed = "gasUsed",
    Nonce = "nonce",
    TxStatus = "txStatus",
    Input = "input",
    TxHash = "txHash",
    Value = "value",
    FromAddr = "fromAddr",
    ToAddr = "toAddr",
    Contract = "contract",
    NetworkID = "networkID"


  TransferCol* {.pure.} = enum
    Id = "id",
    TxType = "tx_type",
    Address = "address",
    BlockNumber = "block_number",
    BlockHash = "block_hash",
    Timestamp = "timestamp",
    GasPrice = "gas_price",
    GasLimit = "gas_limit",
    GasUsed = "gas_used",
    Nonce = "nonce",
    TxStatus = "tx_status",
    Input = "input",
    TxHash = "tx_hash",
    Value = "value",
    FromAddr = "from_addr",
    ToAddr = "to_addr",
    Contract = "contract",
    NetworkID = "network_id"

  Transfer* {.dbTableName("tx_history").} = object 
    # we need to assign our own id because txHash is too ambitious fro ERC20 transfers 
    #ID          common.Hash    `json:"id"`
    id* {.serializedFieldName($TransferType.Id), dbColumnName($TransferCol.Id).}: string
    # type "eth" or "erc20"
    #Type        TransferType   `json:"type"`
    txType* {.serializedFieldName($TransferType.TxType), dbColumnName($TransferCol.TxType)}: TxType
    # not completely sure what this one means 
    #Address     common.Address `json:"address"`
    address* {.serializedFieldName($TransferType.Address), dbColumnName($TransferCol.Address)}: Address
    # is known after range scan
    # BlockNumber *hexutil.Big   `json:"blockNumber"`
    blockNumber* {.serializedFieldName($TransferType.BlockNumber), dbColumnName($TransferCol.BlockNumber)}: int
    # retrieved via `eth_getBlockByNumber`
    # BlockHash   common.Hash    `json:"blockhash"`
    blockHash* {.serializedFieldName($TransferType.BlockHash), dbColumnName($TransferCol.BlockHash)}: string
    # retrieved via `eth_getBlockByNumber`
    #Timestamp   hexutil.int64 `json:"timestamp"`
    timestamp* {.serializedFieldName($TransferType.Timestamp), dbColumnName($TransferCol.Timestamp)}: int
    # retrieved via `eth_getTransactionByHash`
    #GasPrice    *hexutil.Big   `json:"gasPrice"`
    gasPrice* {.serializedFieldName($TransferType.GasPrice), dbColumnName($TransferCol.GasPrice)}: int
    # retrieved via `eth_getTransactionByHash`
    #GasLimit    hexutil.int64 `json:"gasLimit"`
    gasLimit* {.serializedFieldName($TransferType.GasLimit), dbColumnName($TransferCol.GasLimit)}: int64
    # retrieved via `eth_getTransactionReceipt`
    #GasUsed     hexutil.int64 `json:"gasUsed"`
    gasUsed* {.serializedFieldName($TransferType.GasUsed), dbColumnName($TransferCol.GasUsed)}: int64
    # retrieved via `eth_getTransactionByHash`
    #Nonce       hexutil.int64 `json:"nonce"`
    nonce* {.serializedFieldName($TransferType.Nonce), dbColumnName($TransferCol.Nonce)}: int64
    # retrieved via `eth_getTransactionReceipt`
    #TxStatus    hexutil.int64 `json:"txStatus"`
    txStatus* {.serializedFieldName($TransferType.TxStatus), dbColumnName($TransferCol.TxStatus)}: int
    # retrieved via `eth_getTransactionByHash`
    #Input       hexutil.Bytes  `json:"input"`
    input* {.serializedFieldName($TransferType.Input), dbColumnName($TransferCol.Input)}: string
    # retrieved via `eth_getBlockByNumber` or `eth_getLogs`
    #TxHash      common.Hash    `json:"txHash"`
    txHash* {.serializedFieldName($TransferType.TxHash), dbColumnName($TransferCol.TxHash)}: string
    # retrieved via `eth_getTransactionByHash` or `eth_getLogs`
    #Value       *hexutil.Big   `json:"value"`
    value* {.serializedFieldName($TransferType.Value), dbColumnName($TransferCol.Value)}: int
    # retrieved via `eth_getTransactionByHash` or `eth_getLogs`
    #From        common.Address `json:"from"`
    fromAddr* {.serializedFieldName($TransferType.FromAddr), dbColumnName($TransferCol.FromAddr)}: Address
    # retrieved via `eth_getTransactionByHash` or `eth_getLogs`
    #To          common.Address `json:"to"`
    toAddr* {.serializedFieldName($TransferType.ToAddr), dbColumnName($TransferCol.ToAddr)}: Address
    # retrieved via `eth_getTransactionReceipt` or `eth_getLogs`
    #Contract    common.Address `json:"contract"`
    contract* {.serializedFieldName($TransferType.Contract), dbColumnName($TransferCol.Contract)}: Address
    #NetworkID   int64
    networkID* {.serializedFieldName($TransferType.NetworkID), dbColumnName($TransferCol.NetworkID)}:   int64



