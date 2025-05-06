// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/ILinkRegistry.sol";
import "./interfaces/ILinkCreator.sol";

/**
 * @title LinkRegistry
 * @notice Registry for tracking cryptocurrency transfer links
 */
contract LinkRegistry is ILinkRegistry, Ownable {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    // State variables
    address public linkCreator;
    
    // Link data storage
    struct LinkData {
        address creator;
        address tokenAddress;
        uint256 amount;
        uint256 expiration;
        ILinkCreator.LinkStatus status;
        address claimer;
        bytes claimData;
        uint256 createdAt;
        uint256 claimedAt;
    }
    
    // Mappings
    mapping(bytes32 => LinkData) private linkData;
    mapping(address => EnumerableSet.Bytes32Set) private creatorToLinks;
    mapping(address => EnumerableSet.Bytes32Set) private claimerToLinks;
    mapping(ILinkCreator.LinkStatus => EnumerableSet.Bytes32Set) private statusToLinks;
    
    // Statistics
    uint256 public totalLinks;
    uint256 public activeLinks;
    uint256 public claimedLinks;
    uint256 public expiredLinks;
    uint256 public canceledLinks;
    
    // Events
    event LinkCreatorUpdated(address indexed oldLinkCreator, address indexed newLinkCreator);

    /**
     * @notice Constructor
     */
    constructor() Ownable(msg.sender) {
        // Initially, linkCreator is not set. It will be set later by the owner.
    }
    
    /**
     * @dev Modifier to restrict calls to only the LinkCreator contract
     */
    modifier onlyLinkCreator() {
        require(msg.sender == linkCreator, "LinkRegistry: Caller is not the LinkCreator");
        _;
    }
    
    /**
     * @notice Set the LinkCreator contract address
     * @param _linkCreator The address of the LinkCreator contract
     */
    function setLinkCreator(address _linkCreator) external onlyOwner {
        require(_linkCreator != address(0), "LinkRegistry: Invalid LinkCreator address");
        address oldLinkCreator = linkCreator;
        linkCreator = _linkCreator;
        emit LinkCreatorUpdated(oldLinkCreator, _linkCreator);
    }
    
    /**
     * @inheritdoc ILinkRegistry
     */
    function registerLink(
        bytes32 linkId,
        address creator,
        address tokenAddress,
        uint256 amount,
        uint256 expiration,
        bytes calldata claimData
    ) external onlyLinkCreator {
        require(linkData[linkId].creator == address(0), "LinkRegistry: Link already registered");
        
        linkData[linkId] = LinkData({
            creator: creator,
            tokenAddress: tokenAddress,
            amount: amount,
            expiration: expiration,
            status: ILinkCreator.LinkStatus.Active,
            claimer: address(0),
            claimData: claimData,
            createdAt: block.timestamp,
            claimedAt: 0
        });
        
        // Update sets
        creatorToLinks[creator].add(linkId);
        statusToLinks[ILinkCreator.LinkStatus.Active].add(linkId);
        
        // Update statistics
        totalLinks++;
        activeLinks++;
        
        emit LinkRegistered(linkId, creator, tokenAddress, amount, expiration);
    }
    
    /**
     * @inheritdoc ILinkRegistry
     */
    function updateLinkStatus(
        bytes32 linkId,
        ILinkCreator.LinkStatus status,
        address claimer
    ) external onlyLinkCreator {
        require(linkData[linkId].creator != address(0), "LinkRegistry: Link not registered");
        
        LinkData storage link = linkData[linkId];
        ILinkCreator.LinkStatus oldStatus = link.status;
        
        // Remove from old status set
        statusToLinks[oldStatus].remove(linkId);
        
        // Update link status
        link.status = status;
        
        // Update statistics based on the new status
        if (oldStatus == ILinkCreator.LinkStatus.Active) {
            activeLinks--;
        } else if (oldStatus == ILinkCreator.LinkStatus.Claimed) {
            claimedLinks--;
        } else if (oldStatus == ILinkCreator.LinkStatus.Expired) {
            expiredLinks--;
        } else if (oldStatus == ILinkCreator.LinkStatus.Canceled) {
            canceledLinks--;
        }
        
        if (status == ILinkCreator.LinkStatus.Active) {
            activeLinks++;
        } else if (status == ILinkCreator.LinkStatus.Claimed) {
            claimedLinks++;
            // Update claimer info
            link.claimer = claimer;
            link.claimedAt = block.timestamp;
            claimerToLinks[claimer].add(linkId);
        } else if (status == ILinkCreator.LinkStatus.Expired) {
            expiredLinks++;
        } else if (status == ILinkCreator.LinkStatus.Canceled) {
            canceledLinks++;
        }
        
        // Add to new status set
        statusToLinks[status].add(linkId);
        
        emit LinkStatusUpdated(linkId, oldStatus, status);
    }
    
    /**
     * @inheritdoc ILinkRegistry
     */
    function getCreatorLinks(address creator) external view returns (bytes32[] memory linkIds) {
        bytes32[] memory result = new bytes32[](creatorToLinks[creator].length());
        
        for (uint256 i = 0; i < creatorToLinks[creator].length(); i++) {
            result[i] = creatorToLinks[creator].at(i);
        }
        
        return result;
    }
    
    /**
     * @inheritdoc ILinkRegistry
     */
    function getClaimerLinks(address claimer) external view returns (bytes32[] memory linkIds) {
        bytes32[] memory result = new bytes32[](claimerToLinks[claimer].length());
        
        for (uint256 i = 0; i < claimerToLinks[claimer].length(); i++) {
            result[i] = claimerToLinks[claimer].at(i);
        }
        
        return result;
    }
    
    /**
     * @inheritdoc ILinkRegistry
     */
    function getLinksByStatus(ILinkCreator.LinkStatus status) external view returns (bytes32[] memory linkIds) {
        bytes32[] memory result = new bytes32[](statusToLinks[status].length());
        
        for (uint256 i = 0; i < statusToLinks[status].length(); i++) {
            result[i] = statusToLinks[status].at(i);
        }
        
        return result;
    }
    
    /**
     * @inheritdoc ILinkRegistry
     */
    function getExpiringLinks(uint256 thresholdTime) external view returns (bytes32[] memory linkIds) {
        uint256 count = 0;
        
        // First, count the number of links that match our criteria
        for (uint256 i = 0; i < statusToLinks[ILinkCreator.LinkStatus.Active].length(); i++) {
            bytes32 linkId = statusToLinks[ILinkCreator.LinkStatus.Active].at(i);
            if (linkData[linkId].expiration <= thresholdTime) {
                count++;
            }
        }
        
        // Then create and populate the result array
        bytes32[] memory result = new bytes32[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < statusToLinks[ILinkCreator.LinkStatus.Active].length(); i++) {
            bytes32 linkId = statusToLinks[ILinkCreator.LinkStatus.Active].at(i);
            if (linkData[linkId].expiration <= thresholdTime) {
                result[index] = linkId;
                index++;
            }
        }
        
        return result;
    }
    
    /**
     * @inheritdoc ILinkRegistry
     */
    function getLinkStatistics() external view returns (
        uint256 _totalLinks,
        uint256 _activeLinks,
        uint256 _claimedLinks,
        uint256 _expiredLinks,
        uint256 _canceledLinks
    ) {
        return (
            totalLinks,
            activeLinks,
            claimedLinks,
            expiredLinks,
            canceledLinks
        );
    }
    
    /**
     * @notice Get detailed link info
     * @param linkId The unique identifier of the link
     * @return creator The creator of the link
     * @return tokenAddress The token address
     * @return amount The amount of tokens
     * @return expiration The expiration timestamp
     * @return status The status of the link
     * @return claimer The claimer of the link
     * @return createdAt The creation timestamp
     * @return claimedAt The claimed timestamp
     */
    function getLinkInfo(bytes32 linkId) external view returns (
        address creator,
        address tokenAddress,
        uint256 amount,
        uint256 expiration,
        ILinkCreator.LinkStatus status,
        address claimer,
        uint256 createdAt,
        uint256 claimedAt
    ) {
        LinkData memory link = linkData[linkId];
        require(link.creator != address(0), "LinkRegistry: Link not registered");
        
        return (
            link.creator,
            link.tokenAddress,
            link.amount,
            link.expiration,
            link.status,
            link.claimer,
            link.createdAt,
            link.claimedAt
        );
    }
}