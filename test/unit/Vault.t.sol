// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTest} from "../helpers/BaseTest.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VaultTest is BaseTest {
    function test_DepositMintShares() public {
        vm.startPrank(alice);
        token0.approve(address(vault), 100 ether);
        uint256 shares = vault.deposit(100 ether, alice);
        assertGt(shares, 0);
        vm.stopPrank();
    }

    function test_MintDeposit() public {
        vm.startPrank(alice);
        token0.approve(address(vault), 1000 ether);
        uint256 assets = vault.mint(50 ether, alice);
        assertGt(assets, 0);
        vm.stopPrank();
    }

    function test_Withdraw() public {
        vm.startPrank(alice);
        token0.approve(address(vault), 100 ether);
        vault.deposit(100 ether, alice);
        vault.withdraw(50 ether, alice, alice);
        vm.stopPrank();
    }

    function test_Redeem() public {
        vm.startPrank(alice);
        token0.approve(address(vault), 100 ether);
        uint256 shares = vault.deposit(100 ether, alice);
        vault.redeem(shares / 2, alice, alice);
        vm.stopPrank();
    }

    function test_TotalAssetsIncludesYield() public {
        vm.prank(admin);
        token0.mint(admin, 100 ether);
        vm.startPrank(admin);
        token0.approve(address(vault), 100 ether);
        vault.depositYield(100 ether);
        vm.stopPrank();
        assertGe(vault.totalAssets(), 100 ether);
    }

    function test_AccrueYield() public {
        vm.prank(admin);
        token0.mint(admin, 1000 ether);
        vm.startPrank(admin);
        token0.approve(address(vault), 1000 ether);
        vault.depositYield(1000 ether);
        vm.stopPrank();
        vm.warp(block.timestamp + 30 days);
        vault.accrueYield();
    }

    function test_DepositYieldOnlyManager() public {
        vm.prank(alice);
        vm.expectRevert();
        vault.depositYield(1 ether);
    }

    function test_PreviewDeposit() public view {
        assertGt(vault.previewDeposit(100 ether), 0);
    }

    function test_ConvertToShares() public {
        assertEq(vault.convertToShares(0), 0);
    }

    function test_MaxWithdraw() public {
        vm.startPrank(alice);
        token0.approve(address(vault), 10 ether);
        vault.deposit(10 ether, alice);
        assertGt(vault.maxWithdraw(alice), 0);
        vm.stopPrank();
    }

    function test_ERC4626RoundingDepositSmall() public {
        vm.startPrank(alice);
        token0.approve(address(vault), 1);
        uint256 shares = vault.deposit(1, alice);
        assertLe(shares, 1);
        vm.stopPrank();
    }
}
