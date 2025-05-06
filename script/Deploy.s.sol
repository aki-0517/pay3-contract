// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "../lib/forge-std/src/Script.sol";
import {console2} from "../lib/forge-std/src/console2.sol";
import "../src/LinkCreator.sol";
import "../src/LinkRegistry.sol";

/**
 * @title DeployScript
 * @notice Script for deploying the LinkCreator and LinkRegistry contracts
 */
contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address treasury = vm.envAddress("TREASURY_ADDRESS");
        
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
        
        // Add some common ERC20 tokens as supported
        // Example: USDC on Ethereum
        address usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        linkCreator.setTokenSupported(usdcAddress, true);
        console2.log("USDC added as supported token");
        
        // Example: USDT on Ethereum
        address usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        linkCreator.setTokenSupported(usdtAddress, true);
        console2.log("USDT added as supported token");
        
        // Example: DAI on Ethereum
        address daiAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        linkCreator.setTokenSupported(daiAddress, true);
        console2.log("DAI added as supported token");
        
        vm.stopBroadcast();
    }
}