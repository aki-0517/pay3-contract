// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../src/LinkCreator.sol";
import "../src/LinkRegistry.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// Mock ERC20 token for testing
contract MockToken is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}

contract IntegrationTest is Test {
    LinkCreator public linkCreator;
    LinkRegistry public linkRegistry;
    MockToken public mockToken;
    
    address public deployer = address(1);
    address public treasury = address(2);
    address public sender1 = address(3);
    address public sender2 = address(4);
    address public recipient1 = address(5);
    address public recipient2 = address(6);
    
    // Test amounts and durations
    uint256 public constant LINK_AMOUNT_ETH = 1 ether;
    uint256 public constant LINK_AMOUNT_TOKEN = 10 * 10**18;
    uint256 public constant SHORT_EXPIRATION = 1 hours;
    uint256 public constant MEDIUM_EXPIRATION = 1 days;
    uint256 public constant LONG_EXPIRATION = 7 days;

    function setUp() public {
        vm.startPrank(deployer);
        
        // Deploy contracts
        linkRegistry = new LinkRegistry();
        linkCreator = new LinkCreator(address(linkRegistry), treasury);
        linkRegistry.setLinkCreator(address(linkCreator));
        
        // Deploy mock token
        mockToken = new MockToken();
        linkCreator.setTokenSupported(address(mockToken), true);
        
        // Fund test accounts
        vm.deal(sender1, 10 ether);
        vm.deal(sender2, 10 ether);
        mockToken.transfer(sender1, 100 * 10**18);
        mockToken.transfer(sender2, 100 * 10**18);
        
        vm.stopPrank();
    }
    
    function testFullFlowETH() public {
        // 1. Create multiple ETH links
        vm.startPrank(sender1);
        
        bytes32 linkId1 = linkCreator.createLink{value: LINK_AMOUNT_ETH}(
            address(0),
            LINK_AMOUNT_ETH,
            MEDIUM_EXPIRATION,
            "link1"
        );
        
        // 進めるブロックの時間を設定
        vm.warp(block.timestamp + 1);
        // 新しいブロックを生成
        vm.roll(block.number + 1);
        
        bytes32 linkId2 = linkCreator.createLink{value: LINK_AMOUNT_ETH}(
            address(0),
            LINK_AMOUNT_ETH,
            LONG_EXPIRATION,
            "link2"
        );
        
        vm.stopPrank();
        
        // さらにブロックを進める
        vm.warp(block.timestamp + 1);
        vm.roll(block.number + 1);
        
        vm.startPrank(sender2);
        
        bytes32 linkId3 = linkCreator.createLink{value: LINK_AMOUNT_ETH}(
            address(0),
            LINK_AMOUNT_ETH,
            SHORT_EXPIRATION,
            "link3"
        );
        
        vm.stopPrank();
        
        // 2. Check registry contains all links
        bytes32[] memory sender1Links = linkCreator.getCreatorLinks(sender1);
        assertEq(sender1Links.length, 2);
        assertEq(sender1Links[0], linkId1);
        assertEq(sender1Links[1], linkId2);
        
        bytes32[] memory sender2Links = linkCreator.getCreatorLinks(sender2);
        assertEq(sender2Links.length, 1);
        assertEq(sender2Links[0], linkId3);
        
        // 3. Claim a link
        uint256 recipient1BalanceBefore = address(recipient1).balance;
        
        vm.prank(recipient1);
        linkCreator.claimLink(linkId1, recipient1);
        
        uint256 recipient1BalanceAfter = address(recipient1).balance;
        assertEq(recipient1BalanceAfter - recipient1BalanceBefore, 995 * 10**15); // 0.995 ETH after fee
        
        // 4. Cancel a link
        uint256 sender2BalanceBefore = address(sender2).balance;
        
        vm.prank(sender2);
        linkCreator.cancelLink(linkId3);
        
        uint256 sender2BalanceAfter = address(sender2).balance;
        assertEq(sender2BalanceAfter - sender2BalanceBefore, 995 * 10**15); // 0.995 ETH after fee
        
        // 5. Let a link expire and process it
        vm.warp(block.timestamp + LONG_EXPIRATION + 1 hours);
        
        uint256 sender1BalanceBefore = address(sender1).balance;
        
        vm.prank(deployer);
        linkCreator.processExpiredLink(linkId2);
        
        uint256 sender1BalanceAfter = address(sender1).balance;
        assertEq(sender1BalanceAfter - sender1BalanceBefore, 995 * 10**15); // 0.995 ETH after fee
        
        // 6. Check registry statistics
        (
            uint256 totalLinks,
            uint256 activeLinks,
            uint256 claimedLinks,
            uint256 expiredLinks,
            uint256 canceledLinks
        ) = linkRegistry.getLinkStatistics();
        
        assertEq(totalLinks, 3);
        assertEq(activeLinks, 0);
        assertEq(claimedLinks, 1);
        assertEq(expiredLinks, 1);
        assertEq(canceledLinks, 1);
        
        // 7. Check claimer links
        bytes32[] memory claimerLinks = linkRegistry.getClaimerLinks(recipient1);
        assertEq(claimerLinks.length, 1);
        assertEq(claimerLinks[0], linkId1);
    }
    
    function testFullFlowToken() public {
        // 1. Approve tokens for LinkCreator
        vm.startPrank(sender1);
        mockToken.approve(address(linkCreator), 1000 * 10**18);
        vm.stopPrank();
        
        vm.startPrank(sender2);
        mockToken.approve(address(linkCreator), 1000 * 10**18);
        vm.stopPrank();
        
        // 2. Create multiple token links
        vm.startPrank(sender1);
        
        bytes32 linkId1 = linkCreator.createLink(
            address(mockToken),
            LINK_AMOUNT_TOKEN,
            MEDIUM_EXPIRATION,
            ""
        );
        
        bytes32 linkId2 = linkCreator.createLink(
            address(mockToken),
            LINK_AMOUNT_TOKEN * 2,
            LONG_EXPIRATION,
            ""
        );
        
        vm.stopPrank();
        
        vm.startPrank(sender2);
        
        bytes32 linkId3 = linkCreator.createLink(
            address(mockToken),
            LINK_AMOUNT_TOKEN / 2,
            SHORT_EXPIRATION,
            ""
        );
        
        vm.stopPrank();
        
        // 3. Claim a link
        uint256 recipient1BalanceBefore = mockToken.balanceOf(recipient1);
        
        vm.prank(recipient1);
        linkCreator.claimLink(linkId1, recipient1);
        
        uint256 recipient1BalanceAfter = mockToken.balanceOf(recipient1);
        assertEq(recipient1BalanceAfter - recipient1BalanceBefore, 995 * 10**16); // 9.95 tokens after fee
        
        // 4. Cancel a link
        uint256 sender2BalanceBefore = mockToken.balanceOf(sender2);
        
        vm.prank(sender2);
        linkCreator.cancelLink(linkId3);
        
        uint256 sender2BalanceAfter = mockToken.balanceOf(sender2);
        assertEq(sender2BalanceAfter - sender2BalanceBefore, 4975 * 10**15); // 4.975 tokens after fee (half of standard amount)
        
        // 5. Let a link expire and process it
        vm.warp(block.timestamp + LONG_EXPIRATION + 1 hours);
        
        uint256 sender1BalanceBefore = mockToken.balanceOf(sender1);
        
        vm.prank(deployer);
        linkCreator.processExpiredLink(linkId2);
        
        uint256 sender1BalanceAfter = mockToken.balanceOf(sender1);
        assertEq(sender1BalanceAfter - sender1BalanceBefore, 199 * 10**17); // 19.9 tokens after fee (double standard amount)
        
        // 6. Check registry statistics
        (
            uint256 totalLinks,
            uint256 activeLinks,
            uint256 claimedLinks,
            uint256 expiredLinks,
            uint256 canceledLinks
        ) = linkRegistry.getLinkStatistics();
        
        assertEq(totalLinks, 3);
        assertEq(activeLinks, 0);
        assertEq(claimedLinks, 1);
        assertEq(expiredLinks, 1);
        assertEq(canceledLinks, 1);
        
        // 7. Check links by status through registry
        bytes32[] memory claimedLinkIds = linkRegistry.getLinksByStatus(ILinkCreator.LinkStatus.Claimed);
        assertEq(claimedLinkIds.length, 1);
        assertEq(claimedLinkIds[0], linkId1);
        
        bytes32[] memory canceledLinkIds = linkRegistry.getLinksByStatus(ILinkCreator.LinkStatus.Canceled);
        assertEq(canceledLinkIds.length, 1);
        assertEq(canceledLinkIds[0], linkId3);
    }

    // Add a test to verify proper string ID to bytes32 conversion for client integration
    function testClientStringIdConversion() public {
        // Simulate the client-side ID conversion issue
        string memory clientId = "U5I0zmId";
        
        // Method 1: Direct string-to-bytes32 conversion (how client is doing it - causing issues)
        bytes32 incorrectLinkId = bytes32(bytes(clientId));
        
        // Method 2: Proper way to handle the ID if we needed to use string-based IDs
        bytes32 correctLinkId = keccak256(abi.encodePacked(clientId));
        
        // Create a real link
        vm.deal(sender1, 2 ether);
        vm.prank(sender1);
        bytes32 realLinkId = linkCreator.createLink{value: 1 ether}(
            address(0),
            1 ether,
            1 days,
            ""
        );
        
        // Verify the link exists with the correct ID
        ILinkCreator.Link memory link = linkCreator.getLink(realLinkId);
        assertEq(link.creator, sender1);
        
        // Verify the incorrect ID conversion would fail
        vm.expectRevert("LinkCreator: Link does not exist");
        linkCreator.getLink(incorrectLinkId);
        
        // Log for debugging
        console.log("Client String ID:", clientId);
        console.logBytes32(incorrectLinkId); // This is what client-side code is using
        console.logBytes32(realLinkId);      // This is what's actually stored in the contract
        
        // Integration test guidance:
        // 1. Client should either use the hash (keccak256) of the string ID when communicating with the contract
        // 2. OR the client should generate and store the actual bytes32 linkId returned from createLink()
    }
}