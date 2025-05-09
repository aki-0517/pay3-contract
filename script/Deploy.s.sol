// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "../lib/forge-std/src/Script.sol";
import {console2} from "../lib/forge-std/src/console2.sol";
import "../src/LinkCreator.sol";
import "../src/LinkRegistry.sol";
import "../src/Constants.sol";

/**
 * @title DeployScript
 * @notice Script for deploying the LinkCreator and LinkRegistry contracts on Base Sepolia
 */
contract DeployScript is Script {
    function run() external {
        // 環境変数の読み込み
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address treasury = vm.envAddress("TREASURY_ADDRESS");
        
        // Base Sepoliaフォークを作成
        vm.createSelectFork(vm.envString("BASE_SEPOLIA_RPC_URL"));
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy LinkRegistry first
        LinkRegistry linkRegistry = new LinkRegistry();
        console2.log("LinkRegistry deployed at:", address(linkRegistry));
        
        // Deploy LinkCreator with the LinkRegistry address
        LinkCreator linkCreator = new LinkCreator(
            address(linkRegistry),
            treasury
        );
        console2.log("LinkCreator deployed at:", address(linkCreator));
        
        // Set LinkCreator in LinkRegistry
        linkRegistry.setLinkCreator(address(linkCreator));
        console2.log("LinkCreator set in LinkRegistry");
        
        // Base Sepolia上のテストトークンのアドレスを設定
        // Constants.solに定義されたBase Sepolia用のUSDCとUSDTのアドレスを使用
        address sepoliaUSDC = Constants.USDC_ADDRESS_SEPOLIA;
        address sepoliaUSDT = Constants.USDT_ADDRESS_SEPOLIA;
        
        // USDCをサポートトークンとして追加
        linkCreator.setTokenSupported(sepoliaUSDC, true);
        console2.log("USDC added as supported token:", sepoliaUSDC);
        
        // USDTをサポートトークンとして追加
        linkCreator.setTokenSupported(sepoliaUSDT, true);
        console2.log("USDT added as supported token:", sepoliaUSDT);
        
        vm.stopBroadcast();
        
        // デプロイ後の情報をログ出力
        console2.log("=== Deployment Summary ===");
        console2.log("Network: Base Sepolia");
        console2.log("LinkRegistry:", address(linkRegistry));
        console2.log("LinkCreator:", address(linkCreator));
        console2.log("Treasury:", treasury);
        console2.log("Supported tokens:");
        console2.log("- ETH: 0x0000000000000000000000000000000000000000 (default)");
        console2.log("- USDC (Base Sepolia):", sepoliaUSDC);
        console2.log("- USDT (Base Sepolia):", sepoliaUSDT);
    }
}