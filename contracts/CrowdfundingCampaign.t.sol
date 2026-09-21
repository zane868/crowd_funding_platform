// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {CrowdfundingCampaign} from "./CrowdfundingCampaign.sol";

contract CrowdfundingCampaignTest is Test {
    CrowdfundingCampaign campaign;

    address owner = address(0xABCD);
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    uint256 constant GOAL = 10 ether;
    uint256 constant DURATION_DAYS = 30;

    // 状态枚举值：0=Preparing 1=Active 2=Success 3=Failed 4=Closed

    function setUp() public {
        campaign = new CrowdfundingCampaign(owner, "Test Campaign", GOAL, DURATION_DAYS);
    }

    /// 以 owner 身份启动活动
    function _start() internal {
        vm.prank(owner);
        campaign.start();
    }

    /// ============ 构造函数 / 部署 ============

    function test_DeployInitialState() public view {
        assertEq(uint256(campaign.state()), 0);
        assertEq(campaign.owner(), owner);
        assertEq(campaign.name(), "Test Campaign");
        assertEq(campaign.goal(), GOAL);
        assertEq(campaign.totalRaised(), 0);
        assertEq(campaign.deadline(), block.timestamp + DURATION_DAYS * 1 days);
    }

    function test_DeployRejectsZeroOwner() public {
        vm.expectRevert(bytes("CrowdfundingCampaign constructor invalid owner"));
        new CrowdfundingCampaign(address(0), "Test", GOAL, DURATION_DAYS);
    }

    function test_DeployRejectsEmptyName() public {
        vm.expectRevert(bytes("CrowdfundingCampaign constructor invalid name"));
        new CrowdfundingCampaign(owner, "", GOAL, DURATION_DAYS);
    }

    function test_DeployRejectsZeroGoal() public {
        vm.expectRevert(bytes("CrowdfundingCampaign constructor goal must be positive"));
        new CrowdfundingCampaign(owner, "Test", 0, DURATION_DAYS);
    }

    function test_DeployRejectsZeroDuration() public {
        vm.expectRevert(bytes("CrowdfundingCampaign constructor invalid duration"));
        new CrowdfundingCampaign(owner, "Test", GOAL, 0);
    }

    function test_DeployRejectsOver90Days() public {
        vm.expectRevert(bytes("CrowdfundingCampaign constructor invalid duration"));
        new CrowdfundingCampaign(owner, "Test", GOAL, 91);
    }

    /// ============ start() ============

    function test_StartTransitionsToActive() public {
        _start();
        assertEq(uint256(campaign.state()), 1);
    }

    function test_StartRevertsIfNotOwner() public {
        vm.prank(alice);
        vm.expectRevert(bytes("CrowdfundingCampaign not owner"));
        campaign.start();
    }

    function test_StartRevertsIfAlreadyActive() public {
        _start();
        vm.prank(owner);
        vm.expectRevert(bytes("CrowdfundingCampaign invalid state"));
        campaign.start();
    }

    /// ============ contribute() ============

    function test_ContributeRecordsAmount() public {
        _start();
        vm.deal(alice, 5 ether);
        vm.prank(alice);
        campaign.contribute{value: 5 ether}();

        assertEq(campaign.contributions(alice), 5 ether);
        assertEq(campaign.totalRaised(), 5 ether);
    }

    function test_ContributeAccumulatesMultipleTimes() public {
        _start();
        vm.deal(alice, 5 ether);
        vm.startPrank(alice);
        campaign.contribute{value: 3 ether}();
        campaign.contribute{value: 2 ether}();
        vm.stopPrank();

        assertEq(campaign.contributions(alice), 5 ether);
        assertEq(campaign.totalRaised(), 5 ether);
    }

    function test_ContributeTracksContributors() public {
        _start();
        vm.deal(alice, 3 ether);
        vm.deal(bob, 2 ether);
        vm.prank(alice);
        campaign.contribute{value: 3 ether}();
        vm.prank(bob);
        campaign.contribute{value: 2 ether}();

        assertEq(campaign.contributors(0), alice);
        assertEq(campaign.contributors(1), bob);
    }

    function test_ContributeRejectsZeroAmount() public {
        _start();
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectRevert(bytes("CrowdfundingCampaign: contribution must be positive"));
        campaign.contribute{value: 0}();
    }

    function test_ContributeRevertsWhenNotActive() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectRevert(bytes("CrowdfundingCampaign invalid state"));
        campaign.contribute{value: 1 ether}();
    }

    function test_ContributeRevertsAfterDeadline() public {
        _start();
        vm.warp(campaign.deadline() + 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectRevert(bytes("CrowdfundingCampaign expired"));
        campaign.contribute{value: 1 ether}();
    }

    /// ============ finalize() ============

    function test_FinalizeToSuccessAfterDeadline() public {
        _start();
        vm.deal(alice, GOAL);
        vm.prank(alice);
        campaign.contribute{value: GOAL}();

        vm.warp(campaign.deadline() + 1);
        vm.prank(bob);
        campaign.finalize();

        assertEq(uint256(campaign.state()), 2);
    }

    function test_FinalizeToFailedAfterDeadline() public {
        _start();
        vm.deal(alice, 5 ether);
        vm.prank(alice);
        campaign.contribute{value: 5 ether}();

        vm.warp(campaign.deadline() + 1);
        vm.prank(bob);
        campaign.finalize();

        assertEq(uint256(campaign.state()), 3);
    }

    function test_FinalizeRevertsBeforeDeadline() public {
        _start();
        vm.prank(owner);
        vm.expectRevert(bytes("CrowdfundingCampaign: campaign not ended"));
        campaign.finalize();
    }

    /// ============ settle() ============

    function test_SettleEarlyToSuccessByOwner() public {
        _start();
        vm.deal(alice, GOAL);
        vm.prank(alice);
        campaign.contribute{value: GOAL}();

        // 未到期，owner 提前结算
        vm.prank(owner);
        campaign.settle();

        assertEq(uint256(campaign.state()), 2);
    }

    function test_SettleRevertsIfNotOwner() public {
        _start();
        vm.prank(alice);
        vm.expectRevert(bytes("CrowdfundingCampaign not owner"));
        campaign.settle();
    }

    /// ============ withdraw() ============

    function test_WithdrawTransfersFundsAndCloses() public {
        _start();
        vm.deal(alice, GOAL);
        vm.prank(alice);
        campaign.contribute{value: GOAL}();

        // owner 提前结算到 Success
        vm.prank(owner);
        campaign.settle();

        uint256 balanceBefore = owner.balance;
        vm.prank(owner);
        campaign.withdraw();

        assertEq(owner.balance - balanceBefore, GOAL);
        assertEq(uint256(campaign.state()), 4);
        assertEq(address(campaign).balance, 0);
    }

    function test_WithdrawRevertsIfNotOwner() public {
        _start();
        vm.deal(alice, GOAL);
        vm.prank(alice);
        campaign.contribute{value: GOAL}();
        vm.prank(owner);
        campaign.settle();

        vm.prank(alice);
        vm.expectRevert(bytes("CrowdfundingCampaign not owner"));
        campaign.withdraw();
    }

    function test_WithdrawRevertsIfNotSuccess() public {
        _start();
        vm.prank(owner);
        vm.expectRevert(bytes("CrowdfundingCampaign invalid state"));
        campaign.withdraw();
    }

    /// ============ refund() ============

    function test_RefundReturnsContribution() public {
        _start();
        vm.deal(alice, 5 ether);
        vm.prank(alice);
        campaign.contribute{value: 5 ether}();

        // 到期未达标，owner 结算为 Failed
        vm.warp(campaign.deadline() + 1);
        vm.prank(owner);
        campaign.finalize();

        uint256 balanceBefore = alice.balance;
        vm.prank(alice);
        campaign.refund();

        assertEq(alice.balance - balanceBefore, 5 ether);
        assertEq(campaign.contributions(alice), 0);
    }

    function test_RefundRevertsIfNoContribution() public {
        _start();
        vm.warp(campaign.deadline() + 1);
        vm.prank(owner);
        campaign.finalize();

        vm.prank(bob);
        vm.expectRevert(bytes("CrowdfundingCampaign: no contribution to refund"));
        campaign.refund();
    }

    function test_RefundPreventsDoubleRefund() public {
        _start();
        vm.deal(alice, 5 ether);
        vm.prank(alice);
        campaign.contribute{value: 5 ether}();

        vm.warp(campaign.deadline() + 1);
        vm.prank(owner);
        campaign.finalize();

        vm.prank(alice);
        campaign.refund();

        vm.prank(alice);
        vm.expectRevert(bytes("CrowdfundingCampaign: no contribution to refund"));
        campaign.refund();
    }
}
