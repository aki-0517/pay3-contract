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
  LinkRegistry deployed at: 0xd3F08B02CB22DE0faC2ad28E51FA3Ff87AF91E76
  LinkCreator deployed at: 0x6796176Aa3a548b10FCAF8D7f19b3f5A42Cd8995
  LinkCreator set in LinkRegistry
  USDC added as supported token: 0x036CbD53842c5426634e7929541eC2318f3dCF7e
  USDT added as supported token: 0x1260DeB5D5AAa2Bed63A3177d7376263D5210E06
  === Deployment Summary ===
  Network: Base Sepolia
  LinkRegistry: 0xd3F08B02CB22DE0faC2ad28E51FA3Ff87AF91E76
  LinkCreator: 0x6796176Aa3a548b10FCAF8D7f19b3f5A42Cd8995
  Treasury: 0xf87aaAd9d6C1b3ddD0302FE16B30b5E76827B44D
  Supported tokens:
  - ETH: 0x0000000000000000000000000000000000000000 (default)
  - USDC (Base Sepolia): 0x036CbD53842c5426634e7929541eC2318f3dCF7e
  - USDT (Base Sepolia): 0x1260DeB5D5AAa2Bed63A3177d7376263D5210E06

## Setting up 1 EVM.

==========================

Chain 84532

Estimated gas price: 0.000941629 gwei

Estimated total gas used for script: 4406789

Estimated amount required: 0.000004149560319281 ETH

==========================

##### base-sepolia
✅  [Success] Hash: 0x310756ef858cd95ef9202595a3f63d3d21708cec3ca1c3fa981ebf69d7fe447d
Contract Address: 0xd3F08B02CB22DE0faC2ad28E51FA3Ff87AF91E76
Block: 25497898
Paid: 0.000001259631127832 ETH (1297516 gas * 0.000970802 gwei)


##### base-sepolia
✅  [Success] Hash: 0x8dafab08e770a5687ebd5f44475573decb88cdad1efb485106104fd5759fac58
Block: 25497898
Paid: 0.000000045082103276 ETH (46438 gas * 0.000970802 gwei)


##### base-sepolia
✅  [Success] Hash: 0xc303264ab7ec133b3d6190de1bdab6e4993e338a32ccf805c03eaf2f02d8f989
Contract Address: 0x6796176Aa3a548b10FCAF8D7f19b3f5A42Cd8995
Block: 25497898
Paid: 0.000001886206154672 ETH (1942936 gas * 0.000970802 gwei)


##### base-sepolia
✅  [Success] Hash: 0x066860b771fdb85fde0fe4a8086977d127d6380fdea5be2d79542e0be9d5077d
Block: 25497898
Paid: 0.00000004633152545 ETH (47725 gas * 0.000970802 gwei)


##### base-sepolia
✅  [Success] Hash: 0x91c5f52b47fb732c08c966622d62233bbbf87d749157ccf6b7c5d85099bcb92a
Block: 25497899
Paid: 0.000000045082103276 ETH (46438 gas * 0.000970802 gwei)

✅ Sequence #1 on base-sepolia | Total Paid: 0.000003282333014506 ETH (3381053 gas * avg 0.000970802 gwei)
                                                                                                                                                          

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
##
Start verification for (2) contracts
Start verifying contract `0xd3F08B02CB22DE0faC2ad28E51FA3Ff87AF91E76` deployed on base-sepolia
EVM version: cancun
Compiler version: 0.8.26
Optimizations:    200

Submitting verification for [src/LinkRegistry.sol:LinkRegistry] 0xd3F08B02CB22DE0faC2ad28E51FA3Ff87AF91E76.
Submitted contract for verification:
        Response: `OK`
        GUID: `dnxqw4apphalfnsqujtccsbit6g2xrvamhcgcb4qdcq5qwgqch`
        URL: https://sepolia.basescan.org/address/0xd3f08b02cb22de0fac2ad28e51fa3ff87af91e76
Contract verification status:
Response: `NOTOK`
Details: `Pending in queue`
Warning: Verification is still pending...; waiting 15 seconds before trying again (7 tries remaining)
Contract verification status:
Response: `NOTOK`
Details: `Already Verified`
Contract source code already verified
Start verifying contract `0x6796176Aa3a548b10FCAF8D7f19b3f5A42Cd8995` deployed on base-sepolia
EVM version: cancun
Compiler version: 0.8.26
Optimizations:    200
Constructor args: 000000000000000000000000d3f08b02cb22de0fac2ad28e51fa3ff87af91e76000000000000000000000000f87aaad9d6c1b3ddd0302fe16b30b5e76827b44d

Submitting verification for [src/LinkCreator.sol:LinkCreator] 0x6796176Aa3a548b10FCAF8D7f19b3f5A42Cd8995.
Submitted contract for verification:
        Response: `OK`
        GUID: `arttlmcexrmzrymarycldhfwzr2xuwqrpgg5htvquyecc5lsiq`
        URL: https://sepolia.basescan.org/address/0x6796176aa3a548b10fcaf8d7f19b3f5a42cd8995
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