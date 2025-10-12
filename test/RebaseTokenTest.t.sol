// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {IRebaseToken} from "../src/Interfaces/IRebaseToken.sol";
import {Vault} from "../src/Vault.sol";

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
        (bool success, ) = payable(address(vault)).call{value: 1e18}("");
        vm.stopPrank();
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
}  