// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../src/LinkCreator.sol";
import "../src/LinkRegistry.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../src/interfaces/ILinkCreator.sol";

// Mock ERC20 token for testing
contract MockToken is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}

contract LinkCreatorTest is Test {
    LinkCreator public linkCreator;
    LinkRegistry public linkRegistry;
    MockToken public mockToken;
    
    address public deployer = address(1);
    address public treasury = address(2);
    address public sender = address(3);
    address public recipient = address(4);
    
    uint256 public constant LINK_AMOUNT = 1 ether;
    uint256 public constant EXPIRATION_DURATION = 1 days;

    function setUp() public {
        vm.startPrank(deployer);
        
        // Deploy contracts
        linkRegistry = new LinkRegistry();
        linkCreator = new LinkCreator(address(linkRegistry), treasury);
        linkRegistry.setLinkCreator(address(linkCreator));
        
        // Deploy mock token
        mockToken = new MockToken();
        linkCreator.setTokenSupported(address(mockToken), true);
        
        // Transfer tokens to sender
        mockToken.transfer(sender, 100 * 10**18);
        
        vm.stopPrank();
    }
    
    function testCreateETHLink() public {
        vm.deal(sender, 2 ether);
        
        vm.startPrank(sender);
        
        // Create ETH link
        bytes32 linkId = linkCreator.createLink{value: LINK_AMOUNT}(
            address(0),
            LINK_AMOUNT,
            EXPIRATION_DURATION,
            ""
        );
        
        vm.stopPrank();
        
        // Check link details
        ILinkCreator.Link memory link = linkCreator.getLink(linkId);
        assertEq(link.creator, sender);
        assertEq(link.tokenAddress, address(0));
        assertEq(link.amount, 995 * 10**15); // 0.995 ETH after 0.5% fee
        assertEq(uint256(link.status), uint256(ILinkCreator.LinkStatus.Active));
        assertEq(link.claimer, address(0));
        
        // Check treasury received fee
        uint256 treasuryBalance = address(treasury).balance;
        assertEq(treasuryBalance, 5 * 10**15); // 0.005 ETH fee
    }
    
    function testCreateTokenLink() public {
        vm.startPrank(sender);
        
        // Approve tokens for LinkCreator
        mockToken.approve(address(linkCreator), 100 * 10**18);
        
        // Create token link
        bytes32 linkId = linkCreator.createLink(
            address(mockToken),
            10 * 10**18, // 10 tokens
            EXPIRATION_DURATION,
            ""
        );
        
        vm.stopPrank();
        
        // Check link details
        ILinkCreator.Link memory link = linkCreator.getLink(linkId);
        assertEq(link.creator, sender);
        assertEq(link.tokenAddress, address(mockToken));
        assertEq(link.amount, 995 * 10**16); // 9.95 tokens after 0.5% fee
        assertEq(uint256(link.status), uint256(ILinkCreator.LinkStatus.Active));
        
        // Check treasury received fee
        uint256 treasuryBalance = mockToken.balanceOf(treasury);
        assertEq(treasuryBalance, 5 * 10**16); // 0.05 tokens fee
    }
    
    function testClaimETHLink() public {
        vm.deal(sender, 2 ether);
        
        // Create link
        vm.prank(sender);
        bytes32 linkId = linkCreator.createLink{value: LINK_AMOUNT}(
            address(0),
            LINK_AMOUNT,
            EXPIRATION_DURATION,
            ""
        );
        
        uint256 recipientBalanceBefore = address(recipient).balance;
        
        // Claim link
        vm.prank(recipient);
        linkCreator.claimLink(linkId, recipient);
        
        // Check recipient received funds
        uint256 recipientBalanceAfter = address(recipient).balance;
        assertEq(recipientBalanceAfter - recipientBalanceBefore, 995 * 10**15); // 0.995 ETH
        
        // Check link status
        ILinkCreator.Link memory link = linkCreator.getLink(linkId);
        assertEq(uint256(link.status), uint256(ILinkCreator.LinkStatus.Claimed));
        assertEq(link.claimer, recipient);
    }
    
    function testClaimTokenLink() public {
        vm.startPrank(sender);
        
        // Approve tokens
        mockToken.approve(address(linkCreator), 10 * 10**18);
        
        // Create link
        bytes32 linkId = linkCreator.createLink(
            address(mockToken),
            10 * 10**18,
            EXPIRATION_DURATION,
            ""
        );
        
        vm.stopPrank();
        
        uint256 recipientBalanceBefore = mockToken.balanceOf(recipient);
        
        // Claim link
        vm.prank(recipient);
        linkCreator.claimLink(linkId, recipient);
        
        // Check recipient received funds
        uint256 recipientBalanceAfter = mockToken.balanceOf(recipient);
        assertEq(recipientBalanceAfter - recipientBalanceBefore, 995 * 10**16); // 9.95 tokens
        
        // Check link status
        ILinkCreator.Link memory link = linkCreator.getLink(linkId);
        assertEq(uint256(link.status), uint256(ILinkCreator.LinkStatus.Claimed));
        assertEq(link.claimer, recipient);
    }
    
    function testCancelLink() public {
        vm.deal(sender, 2 ether);
        
        // Create link
        vm.prank(sender);
        bytes32 linkId = linkCreator.createLink{value: LINK_AMOUNT}(
            address(0),
            LINK_AMOUNT,
            EXPIRATION_DURATION,
            ""
        );
        
        uint256 senderBalanceBefore = address(sender).balance;
        
        // Cancel link
        vm.prank(sender);
        linkCreator.cancelLink(linkId);
        
        // Check sender received funds back
        uint256 senderBalanceAfter = address(sender).balance;
        assertEq(senderBalanceAfter - senderBalanceBefore, 995 * 10**15); // 0.995 ETH
        
        // Check link status
        ILinkCreator.Link memory link = linkCreator.getLink(linkId);
        assertEq(uint256(link.status), uint256(ILinkCreator.LinkStatus.Canceled));
    }
    
    function testExpiredLink() public {
        vm.deal(sender, 2 ether);
        
        // Create link
        vm.prank(sender);
        bytes32 linkId = linkCreator.createLink{value: LINK_AMOUNT}(
            address(0),
            LINK_AMOUNT,
            EXPIRATION_DURATION,
            ""
        );
        
        // Advance time past expiration
        vm.warp(block.timestamp + EXPIRATION_DURATION + 1);
        
        uint256 senderBalanceBefore = address(sender).balance;
        
        // Process expired link
        vm.prank(deployer);
        linkCreator.processExpiredLink(linkId);
        
        // Check sender received funds back
        uint256 senderBalanceAfter = address(sender).balance;
        assertEq(senderBalanceAfter - senderBalanceBefore, 995 * 10**15); // 0.995 ETH
        
        // Check link status
        ILinkCreator.Link memory link = linkCreator.getLink(linkId);
        assertEq(uint256(link.status), uint256(ILinkCreator.LinkStatus.Expired));
    }
    
    function test_RevertWhen_CancelByNonCreator() public {
        vm.deal(sender, 2 ether);
        
        // Create link
        vm.prank(sender);
        bytes32 linkId = linkCreator.createLink{value: LINK_AMOUNT}(
            address(0),
            LINK_AMOUNT,
            EXPIRATION_DURATION,
            ""
        );
        
        // Try to cancel link by non-creator
        vm.prank(recipient);
        vm.expectRevert("LinkCreator: Only creator can cancel");
        linkCreator.cancelLink(linkId);
    }
    
    function test_RevertWhen_ClaimExpiredLink() public {
        vm.deal(sender, 2 ether);
        
        // Create link
        vm.prank(sender);
        bytes32 linkId = linkCreator.createLink{value: LINK_AMOUNT}(
            address(0),
            LINK_AMOUNT,
            EXPIRATION_DURATION,
            ""
        );
        
        // Advance time past expiration
        vm.warp(block.timestamp + EXPIRATION_DURATION + 1);
        
        // Try to claim expired link
        vm.prank(recipient);
        vm.expectRevert("LinkCreator: Link has expired");
        linkCreator.claimLink(linkId, recipient);
    }
    
    function testLinkRegistry() public {
        vm.deal(sender, 2 ether);
        
        // Create links
        vm.startPrank(sender);
        
        bytes32 linkId1 = linkCreator.createLink{value: 1 ether}(
            address(0),
            1 ether,
            EXPIRATION_DURATION,
            ""
        );
        
        mockToken.approve(address(linkCreator), 10 * 10**18);
        bytes32 linkId2 = linkCreator.createLink(
            address(mockToken),
            10 * 10**18,
            EXPIRATION_DURATION,
            ""
        );
        
        vm.stopPrank();
        
        // Claim one link
        vm.prank(recipient);
        linkCreator.claimLink(linkId1, recipient);
        
        // Check creator links
        bytes32[] memory creatorLinks = linkCreator.getCreatorLinks(sender);
        assertEq(creatorLinks.length, 2);
        assertEq(creatorLinks[0], linkId1);
        assertEq(creatorLinks[1], linkId2);
        
        // Check registry statistics
        (
            uint256 totalLinks,
            uint256 activeLinks,
            uint256 claimedLinks,
            uint256 expiredLinks,
            uint256 canceledLinks
        ) = linkRegistry.getLinkStatistics();
        
        assertEq(totalLinks, 2);
        assertEq(activeLinks, 1);
        assertEq(claimedLinks, 1);
        assertEq(expiredLinks, 0);
        assertEq(canceledLinks, 0);
    }
    
    function testStringToBytes32Conversion() public {
        // Test case for string ID to bytes32 conversion
        string memory stringId = "U5I0zmId";
        
        // Method 1: Left-aligned padding (incorrect - this is what's causing the issue)
        bytes32 incorrectLinkId = bytes32(bytes(stringId));
        
        // Method 2: Proper keccak256 hash (option for generating consistent IDs from strings)
        bytes32 hashedLinkId = keccak256(abi.encodePacked(stringId));
        
        // Create a link with the normal method (this uses a generated ID based on inputs and block data)
        vm.deal(sender, 2 ether);
        vm.prank(sender);
        bytes32 realLinkId = linkCreator.createLink{value: LINK_AMOUNT}(
            address(0),
            LINK_AMOUNT,
            EXPIRATION_DURATION,
            ""
        );
        
        // Verify we can access the link with the real linkId
        ILinkCreator.Link memory link = linkCreator.getLink(realLinkId);
        assertEq(link.creator, sender);
        
        // Using the incorrect ID would fail
        vm.expectRevert("LinkCreator: Link does not exist");
        linkCreator.getLink(incorrectLinkId);
        
        // Using a hashed ID that wasn't actually used to create the link would also fail
        vm.expectRevert("LinkCreator: Link does not exist");
        linkCreator.getLink(hashedLinkId);
        
        // Log values for visual confirmation
        console.log("String ID:", stringId);
        console.log("Incorrect conversion (direct string-to-bytes32):");
        console.logBytes32(incorrectLinkId);
        console.log("Hashed string ID (keccak256):");
        console.logBytes32(hashedLinkId);
        console.log("Actual link ID from contract (generated from inputs):");
        console.logBytes32(realLinkId);
        
        // API Integration Recommendation:
        // 1. When creating a link, store the actual bytes32 returned from createLink()
        // 2. When retrieving a link, use that stored bytes32 value directly
        // 3. If using string IDs in the frontend, convert properly to bytes32 before contract calls
    }
}