// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title Constants
 * @notice Library containing constants used across the crypto link transfer system
 */
library Constants {
    // Time-related constants
    uint256 public constant ONE_HOUR = 3600;
    uint256 public constant ONE_DAY = 86400;
    uint256 public constant ONE_WEEK = 604800;
    uint256 public constant THIRTY_DAYS = 2592000;
    
    // Link-related constants
    uint256 public constant MIN_LINK_DURATION = ONE_HOUR;
    uint256 public constant MAX_LINK_DURATION = THIRTY_DAYS;
    uint256 public constant DEFAULT_LINK_DURATION = ONE_DAY;
    
    // Fee-related constants
    uint256 public constant BASIS_POINTS = 10000; // 100% = 10000 basis points
    uint256 public constant DEFAULT_FEE_BASIS_POINTS = 50; // 0.5% = 50 basis points
    uint256 public constant MAX_FEE_BASIS_POINTS = 500; // 5% = 500 basis points
    
    // Common token addresses on Ethereum mainnet
    address public constant ETH_ADDRESS = address(0);
    address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    // Token addresses for Base Sepolia testnet
    address public constant USDC_ADDRESS_SEPOLIA = 0x036CbD53842c5426634e7929541eC2318f3dCF7e; // Base Sepolia用USDCアドレス
    address public constant USDT_ADDRESS_SEPOLIA = 0x1260DeB5D5AAa2Bed63A3177d7376263D5210E06; // Base Sepolia用USDTアドレス (チェックサム修正済み)
    
    // Link status mapping for frontend representation
    function getLinkStatusName(uint8 status) internal pure returns (string memory) {
        if (status == 0) return "Active";
        if (status == 1) return "Claimed";
        if (status == 2) return "Expired";
        if (status == 3) return "Canceled";
        return "Unknown";
    }
    
    // Helper functions
    function calculateFee(uint256 amount, uint256 feeBasisPoints) internal pure returns (uint256) {
        return (amount * feeBasisPoints) / BASIS_POINTS;
    }
    
    function getAmountAfterFee(uint256 amount, uint256 feeBasisPoints) internal pure returns (uint256) {
        uint256 fee = calculateFee(amount, feeBasisPoints);
        return amount - fee;
    }
}