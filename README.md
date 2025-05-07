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
$ forge build --via-ir
```

### Test

```shell
$ forge test --via-ir
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


```bash
== Logs ==
  LinkRegistry deployed at: 0xA7Ab9e165CDCAE5C646aFcc60b1Ad6084dbc1D9A
  LinkCreator deployed at: 0x33bF6171E2FDA75f50F2Aa39090146d93DAd1b3B
  LinkCreator set in LinkRegistry
  === Deployment Summary ===
  Network: Base Sepolia
  LinkRegistry: 0xA7Ab9e165CDCAE5C646aFcc60b1Ad6084dbc1D9A
  LinkCreator: 0x33bF6171E2FDA75f50F2Aa39090146d93DAd1b3B
  Treasury: 0xf87aaAd9d6C1b3ddD0302FE16B30b5E76827B44D

## Setting up 1 EVM.

==========================

Chain 84532

Estimated gas price: 0.000928313 gwei

Estimated total gas used for script: 4189042

Estimated amount required: 0.000003888742146146 ETH

==========================

##### base-sepolia
✅  [Success] Hash: 0x1445d753511382ebff82c6ae1e5b394d4304d8f3b8e558292a3d220b83f822f5
Block: 25417916
Paid: 0.000000044285697875 ETH (47725 gas * 0.000927935 gwei)


##### base-sepolia
✅  [Success] Hash: 0x027efad72bef1203a84171d02b6ed88b47e9fb619096ffb8e81daa593f4459fe
Contract Address: 0x33bF6171E2FDA75f50F2Aa39090146d93DAd1b3B
Block: 25417916
Paid: 0.00000173905968633 ETH (1874118 gas * 0.000927935 gwei)


##### base-sepolia
✅  [Success] Hash: 0x6ae566f5c22ad23877b0f3ede4616f2e97a332639240f53fa39619a5f769fdcc
Contract Address: 0xA7Ab9e165CDCAE5C646aFcc60b1Ad6084dbc1D9A
Block: 25417916
Paid: 0.00000120401050946 ETH (1297516 gas * 0.000927935 gwei)

✅ Sequence #1 on base-sepolia | Total Paid: 0.000002987355893665 ETH (3219359 gas * avg 0.000927935 gwei)
                                                                                           

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
##
Start verification for (2) contracts
Start verifying contract `0xA7Ab9e165CDCAE5C646aFcc60b1Ad6084dbc1D9A` deployed on base-sepolia
EVM version: cancun
Compiler version: 0.8.26
Optimizations:    200

Submitting verification for [src/LinkRegistry.sol:LinkRegistry] 0xA7Ab9e165CDCAE5C646aFcc60b1Ad6084dbc1D9A.
Submitted contract for verification:
        Response: `OK`
        GUID: `mzs1ijuctudxkeavmxu2e1bn1mqycfi5xgcyvrevvjvrejpsff`
        URL: https://sepolia.basescan.org/address/0xa7ab9e165cdcae5c646afcc60b1ad6084dbc1d9a
Contract verification status:
Response: `NOTOK`
Details: `Pending in queue`
Warning: Verification is still pending...; waiting 15 seconds before trying again (7 tries remaining)
Contract verification status:
Response: `OK`
Details: `Pass - Verified`
Contract successfully verified
Start verifying contract `0x33bF6171E2FDA75f50F2Aa39090146d93DAd1b3B` deployed on base-sepolia
EVM version: cancun
Compiler version: 0.8.26
Optimizations:    200
Constructor args: 000000000000000000000000a7ab9e165cdcae5c646afcc60b1ad6084dbc1d9a000000000000000000000000f87aaad9d6c1b3ddd0302fe16b30b5e76827b44d

Submitting verification for [src/LinkCreator.sol:LinkCreator] 0x33bF6171E2FDA75f50F2Aa39090146d93DAd1b3B.
Submitted contract for verification:
        Response: `OK`
        GUID: `edpysmpv1vvm1ma9a4sczmiyvk6a8hyyim1ffzqrarr9b9j8g6`
        URL: https://sepolia.basescan.org/address/0x33bf6171e2fda75f50f2aa39090146d93dad1b3b
Contract verification status:
Response: `NOTOK`
Details: `Pending in queue`
Warning: Verification is still pending...; waiting 15 seconds before trying again (7 tries remaining)
Contract verification status:
Response: `OK`
Details: `Pass - Verified`
Contract successfully verified
All (2) contracts were verified!

Transactions saved to: /Users/user/Desktop/pay3/pay3-contract/broadcast/Deploy.s.sol/84532/run-latest.json

Sensitive values saved to: /Users/user/Desktop/pay3/pay3-contract/cache/Deploy.s.sol/84532/run-latest.json
```