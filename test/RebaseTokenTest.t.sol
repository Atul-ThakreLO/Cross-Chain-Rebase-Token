// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {IRebaseToken} from "../src/Interfaces/IRebaseToken.sol";
import {Vault} from "../src/Vault.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract RebaseTokenTest is Test {
    RebaseToken private rebaseToken;
    Vault private vault;

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    function setUp() public {
        vm.startPrank(owner);
        rebaseToken = new RebaseToken();
        vault = new Vault(IRebaseToken(address(rebaseToken)));
        rebaseToken.grantMintAndBurnAccess(address(vault));
        // (bool success, ) = payable(address(vault)).call{value: 1e18}("");
        vm.stopPrank();
    }

    function addRewardToVault(uint256 rewardAmount) public {
        (bool success,) = payable(address(vault)).call{value: rewardAmount}("");
    }

    /**
     * @dev we are not using assume here because, terminate the test hence our test well be wasted
     * Instead we use bound which will bound amount between the range.
     * @notice we are using assertApproxEqAbs, due to problem of turncating occuring due to PRECISION_FACTOR,
     * so some last digits are rounded up that's why value changes and assertion will fail.
     * by using assertApproxEqAbs we can manage error of specified delta, assertApproxEqAbs(value1, value2, delta).
     * value of delta is in wei.
     *  here we used 1wei.
     * @param amount The amount to deposit.
     */
    function testDepositeLinear(uint256 amount) public {
        // vm.assume(amount > 1e5);
        amount = bound(amount, 1e5, type(uint96).max);
        vm.startPrank(user);

        vm.deal(user, amount);
        vault.deposit{value: amount}();

        uint256 startingBalance = rebaseToken.balanceOf(user);
        assertApproxEqAbs(amount, startingBalance, 1);

        vm.warp(block.timestamp + 1 hours);
        uint256 middleBalance = rebaseToken.balanceOf(user);
        assertGt(middleBalance, amount);

        vm.warp(block.timestamp + 1 hours);
        uint256 endingBalance = rebaseToken.balanceOf(user);
        assertGt(endingBalance, middleBalance);

        assertApproxEqAbs(middleBalance - startingBalance, endingBalance - middleBalance, 1);
        vm.stopPrank();
    }

    function testRedeemStraightAway(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        vm.startPrank(user);

        vm.deal(user, amount);
        vault.deposit{value: amount}();
        assertApproxEqAbs(rebaseToken.balanceOf(user), amount, 1);

        vault.redeem(type(uint256).max);
        assertEq(rebaseToken.balanceOf(user), 0);
        assertEq(address(user).balance, amount);
        vm.stopPrank();
    }

    function testRedeemAfterSomeTimePassed(uint256 amount, uint256 time) public {
        time = bound(time, 1000, type(uint96).max);
        amount = bound(amount, 1e5, type(uint96).max);

        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();

        vm.warp(block.timestamp + time);
        uint256 balanceAfterSomeTime = rebaseToken.balanceOf(user);

        vm.deal(owner, balanceAfterSomeTime - amount);
        vm.prank(owner);
        addRewardToVault(balanceAfterSomeTime - amount);

        vm.prank(user);
        vault.redeem(type(uint256).max);
        // assertEq(rebaseToken.balanceOf(user), 0);
        assertEq(address(user).balance, balanceAfterSomeTime);
        assertGt(address(user).balance, amount);
    }

    function testTransfer(uint256 amount, uint256 amountToTransfer) public {
        amount = bound(amount, 2e5, type(uint96).max);
        amountToTransfer = bound(amountToTransfer, 1e5, amount - 1e5);
        address user2 = makeAddr("user2");

        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();


        uint256 userBalance = rebaseToken.balanceOf(user);
        uint256 user2Balance = rebaseToken.balanceOf(user2);

        assertEq(userBalance, amount);
        assertEq(user2Balance, 0);

        vm.prank(owner);
        rebaseToken.setInterestRate(4e10);

        // Transfer
        vm.prank(user);
        rebaseToken.transfer(user2, amountToTransfer);

        uint256 userBalanceAfterTransfer = rebaseToken.balanceOf(user);
        uint256 user2BalanceAfterTransfer = rebaseToken.balanceOf(user2);

        assertEq(userBalanceAfterTransfer, userBalance - amountToTransfer);
        assertEq(user2BalanceAfterTransfer, amountToTransfer);

        assertEq(rebaseToken.getUserInterestRate(user), 5e10);
        assertEq(rebaseToken.getUserInterestRate(user2), 5e10);
    }

    function testCannotSetInterestRate(uint256 interestRate) public {
        vm.prank(user);
        vm.expectPartialRevert(bytes4(Ownable.OwnableUnauthorizedAccount.selector));
        // vm.expectRevert();
        rebaseToken.setInterestRate(interestRate);
    }

    function testCannotCallMintAndBurn() public {
        vm.startPrank(user);
        vm.expectPartialRevert(bytes4(IAccessControl.AccessControlUnauthorizedAccount.selector));
        rebaseToken.mint(user, 100);
        vm.expectPartialRevert(bytes4(IAccessControl.AccessControlUnauthorizedAccount.selector));
        rebaseToken.burn(user, 100);
        vm.stopPrank();
    }

    function testGetPrincipleAmount(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);

        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();

        assertEq(rebaseToken.principleBalanceOf(user), amount);

        vm.warp(block.timestamp + 1 hours);
        assertEq(rebaseToken.principleBalanceOf(user), amount);
    }

    function testGetRebaseTokenAddress() public view {
        assertEq(vault.getRebaseTokenAddress(), address(rebaseToken));
    }

    function testInterestRateCanOnlyDecrease(uint256 newInterestRate) public {
        uint256 initialInterestRate = rebaseToken.getInterestRate();
        newInterestRate = bound(newInterestRate, initialInterestRate, type(uint96).max);

        vm.prank(owner);
        vm.expectPartialRevert(bytes4(RebaseToken.ReabaseToken__InterestCanOnlyBeDecrease.selector));
        rebaseToken.setInterestRate(newInterestRate);

        assertEq(rebaseToken.getInterestRate(), initialInterestRate);
    }

    function testCannotSetTheRole() public {
        vm.prank(user);
        vm.expectPartialRevert(bytes4(Ownable.OwnableUnauthorizedAccount.selector));
        rebaseToken.grantMintAndBurnAccess(user);
    }

}
