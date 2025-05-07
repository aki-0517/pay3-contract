// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "../lib/forge-std/src/Script.sol";
import {console2} from "../lib/forge-std/src/console2.sol";
import "../src/LinkCreator.sol";
import "../src/LinkRegistry.sol";

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
        
        // Base Sepolia上でのテストトークンのアドレスを設定
        // 注意: 以下のアドレスは例示用です。実際のBase Sepolia上のトークンアドレスに置き換える必要があります
        // テストネット用のトークンアドレスは別途確認が必要です
        address testUSDC = address(0); // Base Sepolia上のUSDCアドレス
        if (testUSDC != address(0)) {
            linkCreator.setTokenSupported(testUSDC, true);
            console2.log("Test USDC added as supported token");
        }
        
        vm.stopBroadcast();
        
        // デプロイ後の情報をログ出力
        console2.log("=== Deployment Summary ===");
        console2.log("Network: Base Sepolia");
        console2.log("LinkRegistry:", address(linkRegistry));
        console2.log("LinkCreator:", address(linkCreator));
        console2.log("Treasury:", treasury);
    }
}