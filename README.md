# Solidity Auction Smart Contract – Solidity Lecture

This repository contains the source code for the Solidity lecture.
The commits here have been specifically designed to tell the story presented at the lecture.

Reviewing the code here is best done by looking at the commit diffs one-by-one to understand the changes.

## Foundry

This Solidity project has been built with Foundry: a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

> [!NOTE]
> Foundry documentation: [`book.getfoundry.sh`](https://book.getfoundry.sh/)

## Usage

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Format

```shell
forge fmt
```

### Gas Snapshots

```shell
forge snapshot
```

### Anvil

```shell
anvil
```

### Deploy

```shell
forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
cast <subcommand>
```

### Help

```shell
forge --help
anvil --help
$ cast --help
```
