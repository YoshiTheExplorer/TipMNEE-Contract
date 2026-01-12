# TipMNEE Contracts
Smart contracts for TipMNEE, a YouTube tipping escrow system built on Ethereum.
The core contract allows anyone to tip a YouTube creator using an ERC-20 token.
If the creator has not registered a payout wallet, tips are escrowed on-chain until the creator verifies ownership and claims them.

Contracts

TipEscrow.sol
- Accepts ERC-20 tips keyed by channelIdHash
- Holds tips in escrow until claimed
- Supports EIP-712 signature–based claiming
- Allows anyone to trigger withdrawals once a channel is claimed
