import # std libs
  std/[json, strformat, strutils, tables]

import # vendor modules
  chronos, stint, web3

import # nim-status modules
  ./common

contract(Erc20Contract):
  proc name(): string {.view.}
  proc symbol(): string {.view.}
  proc decimals(): Address {.view.}
  proc totalSupply(): UInt256 {.view.}
  proc balanceOf(
    account: Address
  ): UInt256 {.view.}
  proc transfer(
    recipient: Address,
    amount: UInt256
  ): Bool
  proc allowance(
    owner: Address,
    spender: Address,
  ): UInt256 {.view.}
  proc approve(
    spender: Address,
    amount: UInt256
  ): Bool
  proc transferFrom(
    sendr: Address, # intentional misspelling to prevent compilation error
                    # "attempt to redefine 'sender'"
    recipient: Address,
    amount: UInt256
  ): Bool
  proc increaseAllowance(
    spender: Address,
    addedValue: UInt256
  ): Bool
  proc decreaseAllowance(
    spender: Address,
    subtractedValue: UInt256
  ): Bool

contract(MiniMeContract):
  proc MiniMeToken(
    tokenFactory: Address,
    parentToken: Address,
    parentSnapShotBlock: Uint,
    tokenName: string,
    decimalUnits: Uint8,
    tokenSymbol: string,
    transfersEnalbed: Bool
  ) {.constructor.}
  proc transferFrom(
    `from`: Address,
    to: Address,
    ammount: UInt256
  ): Bool
  proc doTransfer(
    `from`: Address,
    to: Address,
    ammount: UInt256
  ): Bool
  proc balanceOf(
    owner: Address
  ): UInt256 {.view.}
  proc approve(
    spender: Address,
    amount: UInt256
  ): Bool
  proc allowance(
    owner: Address,
    spender: Address
  ): UInt256 {.view.}
  proc approveAndCall(
    spender: Address,
    amount: UInt256,
    extraData: Bytes100
  )
  proc totalSupply(): UInt256 {.view.}
  proc balanceOfAt(
    owner: Address,
    blockNumber: Uint
  ): Uint {.view.}
  proc balanceOfAt(
    blockNumber: Uint
  ): Uint {.view.}
  proc createCloneToken(
    cloneTokenName: Bytes256, # string
    cloneDecimalUnits: Uint8,
    cloneTokenSymbol: Bytes256, # string
    snapshotBlock: Uint,
    transfersEnabled: Bool
  ): Address
  proc generateTokens(
    owner: Address,
    amount: Uint
  ): Bool
  proc destroyTokens(
    owner: Address,
    amount: Uint
  ): Bool
  proc enableTransfers(
    transfersEnabled: Bool
  )

type
  BoughtToken* = object
    tokenId*: UInt256

  PackData* = object
    category*: DynamicBytes[32] # bytes4[]
    owner*: Address # address
    mintable*: Bool # bool
    timestamp*: UInt256 # uint256
    price*: UInt256 # uint256
    contentHash*: DynamicBytes[64] # bytes

  SntContract* = MiniMeContract

  TokenData* = object
    category*: DynamicBytes[32] # bytes4[]
    timestamp*: UInt256 # uint256
    contentHash*: DynamicBytes[64] # bytes

contract(StickersContract):
  proc packCount(): UInt256 {.view.}
  proc getPackData(packId: UInt256): PackData {.view.}

contract(StickerMarketContract):
  proc buyToken(
    packId: UInt256,
    destination: Address,
    price: UInt256
  ): BoughtToken
  proc getTokenData(
    tokenId: UInt256
  ): TokenData

contract(StickerPackContract):
  # uncomment all commented methods once
  # https://github.com/status-im/nim-web3/pull/39 is merged
  proc approve(
    to: Address,
    tokenId: UInt256
  )
  proc balanceOf(
    tokenHolder: Address
  ): UInt256 {.view.}
  proc getApproved(
    tokenId: UInt256
  ): Address {.view.}
  proc name(): string {.view.}
  proc ownerOf(
    tokenId: UInt256
  ): Address {.view.}
  proc safeTransferFrom(
    `from`: Address,
    to: Address,
    tokenId: UInt256
  )
  proc symbol(): string {.view.}
  proc tokenByIndex(index: UInt256): UInt256 {.view.}
  proc tokenOfOwnerByIndex(
    owner: Address,
    index: UInt256
  ): UInt256 {.view.}
  proc tokenPackId(
    tokenId: UInt256
  ): UInt256 {.view.}
  proc tokenURI(
    tokenId: UInt256
  ): string {.view.}
  proc totalSupply(): UInt256 {.view.}
  proc setApprovalForAll(
    owner: Address,
    operator: Address
  ): Bool {.view.}
  proc isApprovedForAll(
    owner: Address,
    operator: Address
  ): Bool {.view.}
  proc transferFrom(
    `from`: Address,
    to: Address,
    tokenId: UInt256
  )

# Must export all generated contracts types and methods. Can remove this entire
# export block if https://github.com/status-im/nim-web3/pull/40 is merged.
export
  Erc20Contract, balanceOf,
  MiniMeContract,
  StickersContract, getPackData, packCount,
  StickerMarketContract, buyToken, getTokenData,
  StickerPackContract, approve, balanceOf, getApproved, name, ownerOf,
    safeTransferFrom, symbol, tokenByIndex, tokenOfOwnerByIndex, tokenPackId,
    tokenURI, totalSupply, transferFrom

const
  STICKERS_CONTRACT_ADDRESSES* = {
    NetworkId.Mainnet.int:
      Address.fromHex("0x0577215622f43a39f4bc9640806dfea9b10d2a36"),
    NetworkId.Rinkeby.int:
      Address.fromHex("0x8cc272396Be7583c65BEe82CD7b743c69A87287D"),
    NetworkId.Ropsten.int:
      Address.fromHex("0x8cc272396Be7583c65BEe82CD7b743c69A87287D"),
    NetworkId.Goerli.int:
      Address.fromHex("0x8cc272396Be7583c65BEe82CD7b743c69A87287D")
  }.toTable
  STICKERMARKET_CONTRACT_ADDRESSES* = {
    NetworkId.Mainnet.int:
      Address.fromHex("0x12824271339304d3a9f7e096e62a2a7e73b4a7e7"),
    NetworkId.Rinkeby.int:
      Address.fromHex("0x6CC7274aF9cE9572d22DFD8545Fb8c9C9Bcb48AD"),
    NetworkId.Ropsten.int:
      Address.fromHex("0x6CC7274aF9cE9572d22DFD8545Fb8c9C9Bcb48AD"),
    NetworkId.Goerli.int:
      Address.fromHex("0x6CC7274aF9cE9572d22DFD8545Fb8c9C9Bcb48AD")
  }.toTable
  STICKERPACK_CONTRACT_ADDRESSES* = {
    NetworkId.Mainnet.int:
      Address.fromHex("0x110101156e8F0743948B2A61aFcf3994A8Fb172e"),
    NetworkId.Rinkeby.int:
      Address.fromHex("0xf852198D0385c4B871E0B91804ecd47C6bA97351"),
    NetworkId.Ropsten.int:
      Address.fromHex("0xf852198D0385c4B871E0B91804ecd47C6bA97351"),
    NetworkId.Goerli.int:
      Address.fromHex("0xf852198D0385c4B871E0B91804ecd47C6bA97351")
  }.toTable

proc wei2Eth*(input: Stuint[256], decimals: int = 18): string =
  var one_eth = u256(10).pow(decimals) # fromHex(Stuint[256], "DE0B6B3A7640000")

  var (eth, remainder) = divmod(input, one_eth)
  let leading_zeros = "0".repeat(($one_eth).len - ($remainder).len - 1)

  fmt"{eth}.{leading_zeros}{remainder}"
