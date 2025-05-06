// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title ILinkCreator
 * @notice Interface for creating and managing cryptocurrency transfer links
 */
interface ILinkCreator {
    /**
     * @notice Link status enum
     */
    enum LinkStatus {
        Active,
        Claimed,
        Expired,
        Canceled
    }

    /**
     * @notice Link data structure
     */
    struct Link {
        bytes32 linkId;        // Unique link identifier
        address creator;       // Address of the link creator
        address tokenAddress;  // Address of the token being transferred (address(0) for ETH)
        uint256 amount;        // Amount of tokens/ETH being transferred
        uint256 expiration;    // Timestamp when the link expires
        address claimer;       // Address of the account that claimed the link (address(0) if unclaimed)
        LinkStatus status;     // Status of the link
        bytes claimData;       // Optional data for claiming the link (e.g., for NFTs)
        uint256 createdAt;     // Timestamp when the link was created
        uint256 claimedAt;     // Timestamp when the link was claimed (0 if unclaimed)
    }

    /**
     * @notice Emitted when a new link is created
     */
    event LinkCreated(
        bytes32 indexed linkId,
        address indexed creator,
        address tokenAddress,
        uint256 amount,
        uint256 expiration
    );

    /**
     * @notice Emitted when a link is claimed
     */
    event LinkClaimed(
        bytes32 indexed linkId,
        address indexed creator,
        address indexed claimer,
        address tokenAddress,
        uint256 amount
    );

    /**
     * @notice Emitted when a link is canceled by its creator
     */
    event LinkCanceled(bytes32 indexed linkId, address indexed creator);

    /**
     * @notice Emitted when a link expires and funds are returned
     */
    event LinkExpired(bytes32 indexed linkId, address indexed creator);

    /**
     * @notice Create a new token transfer link
     * @param tokenAddress Address of the token (address(0) for ETH)
     * @param amount Amount of tokens to transfer
     * @param expirationDuration Duration in seconds until the link expires
     * @param claimData Optional data for claiming (e.g., for NFTs)
     * @return linkId The unique identifier of the created link
     */
    function createLink(
        address tokenAddress,
        uint256 amount,
        uint256 expirationDuration,
        bytes calldata claimData
    ) external payable returns (bytes32 linkId);

    /**
     * @notice Claim a link
     * @param linkId The ID of the link to claim
     * @param recipient The address to receive the tokens (must be a valid wallet)
     */
    function claimLink(bytes32 linkId, address recipient) external;

    /**
     * @notice Cancel a link as the creator
     * @param linkId The ID of the link to cancel
     */
    function cancelLink(bytes32 linkId) external;

    /**
     * @notice Process expired links and return funds
     * @param linkId The ID of the expired link
     */
    function processExpiredLink(bytes32 linkId) external;

    /**
     * @notice Get link information
     * @param linkId The ID of the link
     * @return Link data structure
     */
    function getLink(bytes32 linkId) external view returns (Link memory);

    /**
     * @notice Check if a link is claimable
     * @param linkId The ID of the link
     * @return True if the link is claimable
     */
    function isLinkClaimable(bytes32 linkId) external view returns (bool);

    /**
     * @notice Get all links created by an address
     * @param creator The address of the link creator
     * @return Array of link IDs
     */
    function getCreatorLinks(address creator) external view returns (bytes32[] memory);
}