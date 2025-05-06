// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../src/LinkRegistry.sol";
import "../src/interfaces/ILinkCreator.sol";

contract LinkRegistryTest is Test {
    LinkRegistry public linkRegistry;
    
    address public deployer = address(1);
    address public fakeCreator = address(2);
    address public user1 = address(3);
    address public user2 = address(4);
    
    bytes32 public linkId1 = keccak256(abi.encodePacked("link1"));
    bytes32 public linkId2 = keccak256(abi.encodePacked("link2"));
    bytes32 public linkId3 = keccak256(abi.encodePacked("link3"));
    
    function setUp() public {
        vm.startPrank(deployer);
        linkRegistry = new LinkRegistry();
        
        // Set the test contract as the linkCreator for testing purposes
        linkRegistry.setLinkCreator(address(this));
        vm.stopPrank();
    }
    
    function testRegisterLink() public {
        // Register a new link
        linkRegistry.registerLink(
            linkId1,
            user1,
            address(0), // ETH
            1 ether,
            block.timestamp + 1 days,
            ""
        );
        
        // Check link was registered correctly
        (
            address creator,
            address tokenAddress,
            uint256 amount,
            uint256 expiration,
            ILinkCreator.LinkStatus status,
            address claimer,
            uint256 createdAt,
            uint256 claimedAt
        ) = linkRegistry.getLinkInfo(linkId1);
        
        assertEq(creator, user1);
        assertEq(tokenAddress, address(0));
        assertEq(amount, 1 ether);
        assertEq(uint256(status), uint256(ILinkCreator.LinkStatus.Active));
        assertEq(claimer, address(0));
        assertEq(claimedAt, 0);
        
        // Check statistics
        (
            uint256 _totalLinks,
            uint256 _activeLinks,
            uint256 _claimedLinks,
            uint256 _expiredLinks,
            uint256 _canceledLinks
        ) = linkRegistry.getLinkStatistics();
        
        assertEq(_totalLinks, 1);
        assertEq(_activeLinks, 1);
        assertEq(_claimedLinks, 0);
        assertEq(_expiredLinks, 0);
        assertEq(_canceledLinks, 0);
    }
    
    function testUpdateLinkStatus() public {
        // Register a link
        linkRegistry.registerLink(
            linkId1,
            user1,
            address(0),
            1 ether,
            block.timestamp + 1 days,
            ""
        );
        
        // Update link status to claimed
        linkRegistry.updateLinkStatus(
            linkId1,
            ILinkCreator.LinkStatus.Claimed,
            user2
        );
        
        // Check link status
        (
            ,
            ,
            ,
            ,
            ILinkCreator.LinkStatus status,
            address claimer,
            ,
            uint256 claimedAt
        ) = linkRegistry.getLinkInfo(linkId1);
        
        assertEq(uint256(status), uint256(ILinkCreator.LinkStatus.Claimed));
        assertEq(claimer, user2);
        assertEq(claimedAt, block.timestamp);
        
        // Check statistics
        (
            uint256 _totalLinks,
            uint256 _activeLinks,
            uint256 _claimedLinks,
            uint256 _expiredLinks,
            uint256 _canceledLinks
        ) = linkRegistry.getLinkStatistics();
        
        assertEq(_totalLinks, 1);
        assertEq(_activeLinks, 0);
        assertEq(_claimedLinks, 1);
        assertEq(_expiredLinks, 0);
        assertEq(_canceledLinks, 0);
    }
    
    function testMultipleLinks() public {
        // Register multiple links
        linkRegistry.registerLink(
            linkId1,
            user1,
            address(0),
            1 ether,
            block.timestamp + 1 days,
            ""
        );
        
        linkRegistry.registerLink(
            linkId2,
            user1,
            address(1), // Some token
            10 ether,
            block.timestamp + 2 days,
            ""
        );
        
        linkRegistry.registerLink(
            linkId3,
            user2,
            address(0),
            0.5 ether,
            block.timestamp + 3 days,
            ""
        );
        
        // Update statuses
        linkRegistry.updateLinkStatus(
            linkId2,
            ILinkCreator.LinkStatus.Claimed,
            user2
        );
        
        linkRegistry.updateLinkStatus(
            linkId3,
            ILinkCreator.LinkStatus.Canceled,
            address(0)
        );
        
        // Check creator links
        bytes32[] memory user1Links = linkRegistry.getCreatorLinks(user1);
        assertEq(user1Links.length, 2);
        assertEq(user1Links[0], linkId1);
        assertEq(user1Links[1], linkId2);
        
        bytes32[] memory user2Links = linkRegistry.getCreatorLinks(user2);
        assertEq(user2Links.length, 1);
        assertEq(user2Links[0], linkId3);
        
        // Check claimer links
        bytes32[] memory user2Claims = linkRegistry.getClaimerLinks(user2);
        assertEq(user2Claims.length, 1);
        assertEq(user2Claims[0], linkId2);
        
        // Check links by status
        bytes32[] memory activeLinks = linkRegistry.getLinksByStatus(ILinkCreator.LinkStatus.Active);
        assertEq(activeLinks.length, 1);
        assertEq(activeLinks[0], linkId1);
        
        bytes32[] memory claimedLinks = linkRegistry.getLinksByStatus(ILinkCreator.LinkStatus.Claimed);
        assertEq(claimedLinks.length, 1);
        assertEq(claimedLinks[0], linkId2);
        
        bytes32[] memory canceledLinks = linkRegistry.getLinksByStatus(ILinkCreator.LinkStatus.Canceled);
        assertEq(canceledLinks.length, 1);
        assertEq(canceledLinks[0], linkId3);
        
        // Check statistics
        (
            uint256 _totalLinks,
            uint256 _activeLinks,
            uint256 _claimedLinks,
            uint256 _expiredLinks,
            uint256 _canceledLinks
        ) = linkRegistry.getLinkStatistics();
        
        assertEq(_totalLinks, 3);
        assertEq(_activeLinks, 1);
        assertEq(_claimedLinks, 1);
        assertEq(_expiredLinks, 0);
        assertEq(_canceledLinks, 1);
    }
    
    function testGetExpiringLinks() public {
        // Register links with different expiration times
        linkRegistry.registerLink(
            linkId1,
            user1,
            address(0),
            1 ether,
            block.timestamp + 1 hours,
            ""
        );
        
        linkRegistry.registerLink(
            linkId2,
            user1,
            address(0),
            1 ether,
            block.timestamp + 10 hours,
            ""
        );
        
        linkRegistry.registerLink(
            linkId3,
            user1,
            address(0),
            1 ether,
            block.timestamp + 24 hours,
            ""
        );
        
        // Check for links expiring in the next 12 hours
        bytes32[] memory expiringLinks = linkRegistry.getExpiringLinks(block.timestamp + 12 hours);
        assertEq(expiringLinks.length, 2); // Should include linkId1 and linkId2
        
        // Check if the results contain the expected links
        bool foundLink1 = false;
        bool foundLink2 = false;
        
        for (uint256 i = 0; i < expiringLinks.length; i++) {
            if (expiringLinks[i] == linkId1) {
                foundLink1 = true;
            }
            if (expiringLinks[i] == linkId2) {
                foundLink2 = true;
            }
        }
        
        assertTrue(foundLink1);
        assertTrue(foundLink2);
    }
    
    function test_RevertWhen_NonLinkCreator() public {
        // Try to register a link from an unauthorized address
        vm.prank(fakeCreator);
        vm.expectRevert("LinkRegistry: Caller is not the LinkCreator");
        linkRegistry.registerLink(
            linkId1,
            user1,
            address(0),
            1 ether,
            block.timestamp + 1 days,
            ""
        );
    }
    
    function test_RevertWhen_DuplicateLink() public {
        // Register a link
        linkRegistry.registerLink(
            linkId1,
            user1,
            address(0),
            1 ether,
            block.timestamp + 1 days,
            ""
        );
        
        // Try to register the same link again
        vm.expectRevert("LinkRegistry: Link already registered");
        linkRegistry.registerLink(
            linkId1,
            user2,
            address(0),
            2 ether,
            block.timestamp + 2 days,
            ""
        );
    }
    
    function test_RevertWhen_UpdateNonExistentLink() public {
        // Try to update a link that doesn't exist
        vm.expectRevert("LinkRegistry: Link not registered");
        linkRegistry.updateLinkStatus(
            bytes32(uint256(1234)),
            ILinkCreator.LinkStatus.Claimed,
            user1
        );
    }
    
    function testSetLinkCreator() public {
        vm.prank(deployer);
        linkRegistry.setLinkCreator(address(123));
        
        // Now trying to call registerLink should fail
        vm.expectRevert("LinkRegistry: Caller is not the LinkCreator");
        linkRegistry.registerLink(
            linkId1,
            user1,
            address(0),
            1 ether,
            block.timestamp + 1 days,
            ""
        );
    }
}