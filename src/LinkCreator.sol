// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import "./interfaces/ILinkCreator.sol";
import "./interfaces/ILinkRegistry.sol";

/**
 * @title LinkCreator
 * @notice Implementation of the crypto link creation and management system
 * @dev Works with Coinbase SDK for Smart Wallet and Paymaster functionality
 */
contract LinkCreator is ILinkCreator, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    // Constants
    uint256 public constant MAX_EXPIRATION = 30 days;
    uint256 public constant MIN_EXPIRATION = 1 hours;
    
    // State variables
    ILinkRegistry public linkRegistry;
    
    // Mapping from linkId to Link
    mapping(bytes32 => Link) private links;
    // Mapping from creator to their links
    mapping(address => bytes32[]) private creatorLinks;
    // Platform fee percentage (basis points: 100 = 1%)
    uint256 public platformFee = 50; // 0.5% default
    // Treasury address
    address public treasury;
    
    // Supported token list
    mapping(address => bool) public supportedTokens;
    
    /**
     * @notice Constructor
     * @param _linkRegistry Address of the LinkRegistry contract
     * @param _treasury Address of the treasury
     */
    constructor(
        address _linkRegistry,
        address _treasury
    ) Ownable(msg.sender) {
        require(_linkRegistry != address(0), "LinkCreator: Invalid link registry address");
        require(_treasury != address(0), "LinkCreator: Invalid treasury address");
        
        linkRegistry = ILinkRegistry(_linkRegistry);
        treasury = _treasury;
        
        // Add ETH as supported by default (represented by address(0))
        supportedTokens[address(0)] = true;
    }
    
    /**
     * @inheritdoc ILinkCreator
     */
    function createLink(
        address tokenAddress,
        uint256 amount,
        uint256 expirationDuration,
        bytes calldata claimData
    ) external payable nonReentrant returns (bytes32 linkId) {
        require(expirationDuration >= MIN_EXPIRATION, "LinkCreator: Expiration too short");
        require(expirationDuration <= MAX_EXPIRATION, "LinkCreator: Expiration too long");
        require(amount > 0, "LinkCreator: Amount must be greater than 0");
        require(supportedTokens[tokenAddress], "LinkCreator: Token not supported");
        
        // Calculate platform fee
        uint256 fee = (amount * platformFee) / 10000;
        uint256 amountAfterFee = amount - fee;
        
        // Handle token transfers
        if (tokenAddress == address(0)) {
            // ETH transfer
            require(msg.value == amount, "LinkCreator: Incorrect ETH amount");
            
            // Pay fee to treasury
            if (fee > 0) {
                (bool success, ) = treasury.call{value: fee}("");
                require(success, "LinkCreator: Fee transfer failed");
            }
        } else {
            // ERC20 transfer
            IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
            
            // Pay fee to treasury
            if (fee > 0) {
                IERC20(tokenAddress).safeTransfer(treasury, fee);
            }
        }
        
        // Generate link ID using creator address, token, amount, and current block
        linkId = keccak256(
            abi.encodePacked(
                msg.sender,
                tokenAddress,
                amountAfterFee,
                block.timestamp,
                block.prevrandao
            )
        );
        
        // Store the link
        uint256 expiration = block.timestamp + expirationDuration;
        links[linkId] = Link({
            linkId: linkId,
            creator: msg.sender,
            tokenAddress: tokenAddress,
            amount: amountAfterFee,
            expiration: expiration,
            claimer: address(0),
            status: LinkStatus.Active,
            claimData: claimData,
            createdAt: block.timestamp,
            claimedAt: 0
        });
        
        // Add to creator's links
        creatorLinks[msg.sender].push(linkId);
        
        // Register the link in the registry
        linkRegistry.registerLink(
            linkId,
            msg.sender,
            tokenAddress,
            amountAfterFee,
            expiration,
            claimData
        );
        
        emit LinkCreated(linkId, msg.sender, tokenAddress, amountAfterFee, expiration);
        
        return linkId;
    }
    
    /**
     * @inheritdoc ILinkCreator
     */
    function claimLink(bytes32 linkId, address recipient) external nonReentrant {
        Link storage link = links[linkId];
        
        require(link.linkId == linkId, "LinkCreator: Link does not exist");
        require(link.status == LinkStatus.Active, "LinkCreator: Link is not active");
        require(block.timestamp < link.expiration, "LinkCreator: Link has expired");
        require(recipient != address(0), "LinkCreator: Invalid recipient");
        
        // Update link status
        link.status = LinkStatus.Claimed;
        link.claimer = recipient;
        link.claimedAt = block.timestamp;
        
        // Transfer tokens to recipient
        if (link.tokenAddress == address(0)) {
            // ETH transfer
            (bool success, ) = recipient.call{value: link.amount}("");
            require(success, "LinkCreator: ETH transfer failed");
        } else {
            // ERC20 transfer
            IERC20(link.tokenAddress).safeTransfer(recipient, link.amount);
        }
        
        // Update link registry
        linkRegistry.updateLinkStatus(linkId, LinkStatus.Claimed, recipient);
        
        emit LinkClaimed(
            linkId,
            link.creator,
            recipient,
            link.tokenAddress,
            link.amount
        );
    }
    
    /**
     * @inheritdoc ILinkCreator
     */
    function cancelLink(bytes32 linkId) external nonReentrant {
        Link storage link = links[linkId];
        
        require(link.linkId == linkId, "LinkCreator: Link does not exist");
        require(link.status == LinkStatus.Active, "LinkCreator: Link is not active");
        require(msg.sender == link.creator, "LinkCreator: Only creator can cancel");
        
        // Update link status
        link.status = LinkStatus.Canceled;
        
        // Transfer tokens back to creator
        if (link.tokenAddress == address(0)) {
            // ETH transfer
            (bool success, ) = link.creator.call{value: link.amount}("");
            require(success, "LinkCreator: ETH transfer failed");
        } else {
            // ERC20 transfer
            IERC20(link.tokenAddress).safeTransfer(link.creator, link.amount);
        }
        
        // Update link registry
        linkRegistry.updateLinkStatus(linkId, LinkStatus.Canceled, address(0));
        
        emit LinkCanceled(linkId, link.creator);
    }
    
    /**
     * @inheritdoc ILinkCreator
     */
    function processExpiredLink(bytes32 linkId) external nonReentrant {
        Link storage link = links[linkId];
        
        require(link.linkId == linkId, "LinkCreator: Link does not exist");
        require(link.status == LinkStatus.Active, "LinkCreator: Link is not active");
        require(block.timestamp >= link.expiration, "LinkCreator: Link has not expired");
        
        // Update link status
        link.status = LinkStatus.Expired;
        
        // Transfer tokens back to creator
        if (link.tokenAddress == address(0)) {
            // ETH transfer
            (bool success, ) = link.creator.call{value: link.amount}("");
            require(success, "LinkCreator: ETH transfer failed");
        } else {
            // ERC20 transfer
            IERC20(link.tokenAddress).safeTransfer(link.creator, link.amount);
        }
        
        // Update link registry
        linkRegistry.updateLinkStatus(linkId, LinkStatus.Expired, address(0));
        
        emit LinkExpired(linkId, link.creator);
    }
    
    /**
     * @inheritdoc ILinkCreator
     */
    function getLink(bytes32 linkId) external view returns (Link memory) {
        require(links[linkId].linkId == linkId, "LinkCreator: Link does not exist");
        return links[linkId];
    }
    
    /**
     * @inheritdoc ILinkCreator
     */
    function isLinkClaimable(bytes32 linkId) external view returns (bool) {
        Link memory link = links[linkId];
        return (
            link.linkId == linkId &&
            link.status == LinkStatus.Active &&
            block.timestamp < link.expiration
        );
    }
    
    /**
     * @inheritdoc ILinkCreator
     */
    function getCreatorLinks(address creator) external view returns (bytes32[] memory) {
        return creatorLinks[creator];
    }
    
    /**
     * @notice Set platform fee percentage (owner only)
     * @param _platformFee New fee in basis points (100 = 1%)
     */
    function setPlatformFee(uint256 _platformFee) external onlyOwner {
        require(_platformFee <= 500, "LinkCreator: Fee too high"); // Max 5%
        platformFee = _platformFee;
    }
    
    /**
     * @notice Set treasury address (owner only)
     * @param _treasury New treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "LinkCreator: Invalid treasury address");
        treasury = _treasury;
    }
    
    /**
     * @notice Add or remove a supported token
     * @param tokenAddress The token address to update
     * @param supported Whether the token is supported
     */
    function setTokenSupported(address tokenAddress, bool supported) external onlyOwner {
        supportedTokens[tokenAddress] = supported;
    }
    
    /**
     * @notice Rescue ERC20 tokens accidentally sent to this contract
     * @param token Token address
     * @param amount Amount to rescue
     */
    function rescueERC20(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }
    
    /**
     * @notice Rescue ETH accidentally sent to this contract
     * @param amount Amount to rescue
     */
    function rescueETH(uint256 amount) external onlyOwner {
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "LinkCreator: ETH transfer failed");
    }
    
    /**
     * @notice Receive function to allow contract to receive ETH
     */
    receive() external payable {}
}