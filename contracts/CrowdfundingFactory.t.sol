// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {CrowdfundingFactory} from "./CrowdfundingFactory.sol";
import {CrowdfundingCampaign} from "./CrowdfundingCampaign.sol";

contract CrowdfundingFactoryTest is Test {
    CrowdfundingFactory factory;

    function setUp() public {
        factory = new CrowdfundingFactory();
    }

    function testCreateCampaign() public {
        address alice = address(0xA11CE);
        vm.prank(alice);
        address created = factory.createCampaign("First campaign", 1 ether, 30);
        CrowdfundingCampaign campaign = CrowdfundingCampaign(created);
        assertEq(campaign.owner(), alice);
        assertEq(campaign.name(), "First campaign");
        assertEq(campaign.goal(), 1 ether);
        assertEq(campaign.deadline(), block.timestamp + 30 days);
        assertEq(uint256(campaign.state()), 0);
        assertEq(factory.getCampaignCount(), 1);
        assertEq(factory.getCampaigns()[0], created);
        assertEq(factory.getUserCampaigns(alice)[0], created);
    }

    function testUserCampaignsRemainSeparate() public {
        address alice = address(0xA11CE);
        address bob = address(0xB0B);
        vm.prank(alice);
        address first = factory.createCampaign("Alice first", 1 ether, 1);
        vm.prank(bob);
        address second = factory.createCampaign("Bob first", 2 ether, 90);
        vm.prank(alice);
        address third = factory.createCampaign("Alice second", 3 ether, 30);
        address[] memory aliceCampaigns = factory.getUserCampaigns(alice);
        assertEq(aliceCampaigns.length, 2);
        assertEq(aliceCampaigns[0], first);
        assertEq(aliceCampaigns[1], third);
        assertEq(factory.getUserCampaigns(bob)[0], second);
        assertEq(factory.getUserCampaigns(address(0x123)).length, 0);
        assertEq(factory.getCampaignCount(), 3);
    }

    function testInvalidCampaignDoesNotChangeRegistry() public {
        vm.expectRevert(
            bytes("CrowdfundingCampaign constructor invalid duration")
        );
        factory.createCampaign("Invalid", 1 ether, 0);
        assertEq(factory.getCampaignCount(), 0);
        assertEq(factory.getUserCampaigns(address(this)).length, 0);
    }
}
