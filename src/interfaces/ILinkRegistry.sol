// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../interfaces/ILinkCreator.sol";

/**
 * @title ILinkRegistry
 * @notice Interface for registering and tracking cryptocurrency transfer links
 */
interface ILinkRegistry {
    /**
     * @notice Emitted when a link is registered
     */
    event LinkRegistered(
        bytes32 indexed linkId,
        address indexed creator,
        address tokenAddress,
        uint256 amount,
        uint256 expiration
    );

    /**
     * @notice Emitted when a link status is updated
     */
    event LinkStatusUpdated(
        bytes32 indexed linkId,
        ILinkCreator.LinkStatus oldStatus,
        ILinkCreator.LinkStatus newStatus
    );

    /**
     * @notice Register a new link
     * @param linkId The unique identifier of the link
     * @param creator The creator of the link
     * @param tokenAddress The token address (address(0) for ETH)
     * @param amount The amount of tokens
     * @param expiration The expiration timestamp
     * @param claimData Optional data for claiming
     */
    function registerLink(
        bytes32 linkId,
        address creator,
        address tokenAddress,
        uint256 amount,
        uint256 expiration,
        bytes calldata claimData
    ) external;

    /**
     * @notice Update the status of a link
     * @param linkId The unique identifier of the link
     * @param status The new status of the link
     * @param claimer The address of the claimer (if status is Claimed)
     */
    function updateLinkStatus(
        bytes32 linkId,
        ILinkCreator.LinkStatus status,
        address claimer
    ) external;

    /**
     * @notice Get all links created by an address
     * @param creator The address of the creator
     * @return linkIds Array of link IDs
     */
    function getCreatorLinks(address creator) external view returns (bytes32[] memory linkIds);

    /**
     * @notice Get all links claimed by an address
     * @param claimer The address of the claimer
     * @return linkIds Array of link IDs
     */
    function getClaimerLinks(address claimer) external view returns (bytes32[] memory linkIds);

    /**
     * @notice Get links by status
     * @param status The status to filter by
     * @return linkIds Array of link IDs
     */
    function getLinksByStatus(ILinkCreator.LinkStatus status) external view returns (bytes32[] memory linkIds);

    /**
     * @notice Get links that are about to expire
     * @param thresholdTime The time threshold to check against
     * @return linkIds Array of link IDs
     */
    function getExpiringLinks(uint256 thresholdTime) external view returns (bytes32[] memory linkIds);

    /**
     * @notice Get link statistics
     * @return totalLinks Total number of links created
     * @return activeLinks Number of active links
     * @return claimedLinks Number of claimed links
     * @return expiredLinks Number of expired links
     * @return canceledLinks Number of canceled links
     */
    function getLinkStatistics() external view returns (
        uint256 totalLinks,
        uint256 activeLinks,
        uint256 claimedLinks,
        uint256 expiredLinks,
        uint256 canceledLinks
    );
}