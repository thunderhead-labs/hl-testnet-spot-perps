# Hyperliquid Spot Perps

### Introduction
Hyperliquid does not currently have perps for spot assets. With the introduction of the testnet evm that has access to spot prices, we can create GMX style perps. This implementation was done in 2 hours from start to finish and is very primitive. 


### Getting Started

First claim some gas token from the faucet:  
`curl -X POST --header "Content-Type: application/json" --data '{"type":"ethFaucet", "user": "0x7735cE49c065d175D5fC39CF030586575b5194c5"}' https://api.hyperliquid-testnet.xyz/info`

To deploy:  
` forge script script/Main.s.sol --rpc-url $rpc --broadcast`

This will deploy the `Perpetual` contract which will deploy a USDC token within its constructor.

### Some Usage Instructions

1. Ensure you've claimed gas from the faucet as mentioned above
2. `Perpetual.faucet()` can be queried once per address and will cause the user to receive 10k mock USDC.
3. Use `Perpetual.openPosition(uint256 margin, uint256 usdNotional, bool isLong, uint256 assetIndex)` to ape into something. `margin` is the amount of USDC that will be transferred out of your account (no approval needed, `Perpetual` has god approval). `usdNotional` is the amount of the token perp that will be created (i.e `usdNotional / margin` is your leverage, which cannot exceed 1000). `isLong = false` for short `isLong = true` for long. `assetIndex` is the index of the asset that you would like to purchase. It is unclear how that aligns with the asset name on testnet since there are much more assets on testnet then prices returned by the oracle. Use `Perpetual.getMarkOraclePxs()` which will return the prices (just a pass through to the oracle for simplicity, appears to be 10**3 precision).
4. Use `Perpetual.closePosition(uint256 tokenNotional, uint256 assetIndex)` to close a position. This will transfer the user back their remaining margin + profit if any (position is checked for liquidation prior to closing). `tokenNotional` is demoninated in the token count - you can use `Perpetual.balanceOfNotional(address user, uint256 assetIndex)` to find out how much notional someone has in their position. 
5. `Perpetual.liquidateAllUsers()` should be called periodically to ensure there isn't any bad-debt (there probably will be since leverage is super high and LTV is 1 but we don't really care here).
6. `Perpetual.getUserPositions(address user)` to return information for a users given positions such as pnl, margin, initial debt, etc. 
7. `Perpetual.getPositionValue(address user, uint256 assetIndex)` gives the USDC value of a given perp position. 
8. `Perpetual.getPositionPnl(address user, uint256 assetIndex)` gives the USDC PnL of a given perp position (can be negative obviously).

### Contract Addresses

`Perpetual = 0x8ac4059F12cDf521D94DBd3bfB3981709Dd345cc`  
`USDC = 0x897415a1C3A1352ae7eF0CC0247a829dD4428Fc2`

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
