// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTest} from "../helpers/BaseTest.sol";

contract LendingTest is BaseTest {
    function test_DepositCollateral() public {
        vm.startPrank(alice);
        token0.approve(address(lending), 100 ether);
        lending.depositCollateral(100 ether);
        assertEq(lending.collateralBalance(alice), 100 ether);
        vm.stopPrank();
    }

    function test_DepositRevertZero() public {
        vm.expectRevert();
        lending.depositCollateral(0);
    }

    function test_BorrowWithinLtv() public {
        _deposit(alice, 1000 ether);
        vm.prank(alice);
        lending.borrow(100 ether);
        assertEq(lending.borrowBalance(alice), 100 ether);
    }

    function test_BorrowRevertUnhealthy() public {
        _deposit(alice, 10 ether);
        vm.startPrank(alice);
        vm.expectRevert();
        lending.borrow(20_000 ether);
        vm.stopPrank();
    }

    function test_Repay() public {
        _depositAndBorrow(alice, 1000 ether, 50 ether);
        vm.startPrank(alice);
        token1.approve(address(lending), 50 ether);
        lending.repay(50 ether);
        assertEq(lending.borrowBalance(alice), 0);
        vm.stopPrank();
    }

    function test_WithdrawCollateralHealthy() public {
        _deposit(alice, 1000 ether);
        vm.startPrank(alice);
        lending.withdrawCollateral(100 ether);
        vm.stopPrank();
    }

    function test_WithdrawRevertUnhealthy() public {
        _deposit(alice, 100 ether);
        uint256 maxB = lending.maxBorrowable(alice);
        vm.prank(alice);
        lending.borrow(maxB);
        vm.prank(admin);
        feed.setAnswer(100e8);
        vm.prank(alice);
        vm.expectRevert();
        lending.withdrawCollateral(1 ether);
    }

    function test_HealthFactorMaxWhenNoDebt() public view {
        assertEq(lending.healthFactor(alice), type(uint256).max);
    }

    function test_LiquidateUnhealthy() public {
        _deposit(alice, 200 ether);
        uint256 maxB = lending.maxBorrowable(alice);
        vm.prank(alice);
        lending.borrow(maxB);
        vm.prank(admin);
        feed.setAnswer(100e8);
        vm.prank(admin);
        token1.mint(liquidator, maxB);
        vm.startPrank(liquidator);
        token1.approve(address(lending), maxB);
        lending.liquidate(alice, maxB / 2);
        vm.stopPrank();
    }

    function test_LiquidateRevertHealthy() public {
        _deposit(alice, 1000 ether);
        vm.prank(liquidator);
        vm.expectRevert();
        lending.liquidate(alice, 1 ether);
    }

    function test_SetLtvAdminOnly() public {
        vm.prank(bob);
        vm.expectRevert();
        lending.setLtv(7000);
    }

    function test_SetLtv() public {
        vm.prank(admin);
        lending.setLtv(7000);
        assertEq(lending.ltvBps(), 7000);
    }

    function test_MaxBorrowable() public {
        _deposit(alice, 1000 ether);
        assertGt(lending.maxBorrowable(alice), 0);
    }

    function test_PauseBlocksDeposit() public {
        vm.prank(admin);
        lending.pause();
        vm.expectRevert();
        lending.depositCollateral(1 ether);
    }

    function test_StalePriceRevertsBorrow() public {
        _deposit(alice, 1000 ether);
        vm.warp(10_000);
        feed.setStale();
        vm.prank(alice);
        vm.expectRevert();
        lending.borrow(1 ether);
    }

    function _deposit(address user, uint256 amt) internal {
        vm.startPrank(user);
        token0.approve(address(lending), amt);
        lending.depositCollateral(amt);
        vm.stopPrank();
    }

    function _depositAndBorrow(address user, uint256 col, uint256 borrowAmt) internal {
        _deposit(user, col);
        vm.prank(user);
        lending.borrow(borrowAmt);
    }
}
