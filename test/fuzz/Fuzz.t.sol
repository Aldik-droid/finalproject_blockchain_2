// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTest} from "../helpers/BaseTest.sol";
import {AssemblyMath} from "../../src/utils/AssemblyMath.sol";

contract FuzzTest is BaseTest {
    function setUp() public override {
        super.setUp();
        vm.startPrank(alice);
        token0.approve(address(amm), type(uint256).max);
        token1.approve(address(amm), type(uint256).max);
        amm.addLiquidity(10_000 ether, 10_000 ether, 0, 0);
        vm.stopPrank();
    }

    function testFuzz_SwapNeverExceedsReserves(uint256 amountIn) public {
        amountIn = bound(amountIn, 1, 1000 ether);
        vm.startPrank(bob);
        token0.approve(address(amm), amountIn);
        (uint256 r0, uint256 r1) = amm.getReserves();
        uint256 out = amm.swapExactTokensForTokens(amountIn, 0, true, bob);
        assertLe(out, r1);
        (uint256 r0After,) = amm.getReserves();
        assertGe(r0After, r0);
        vm.stopPrank();
    }

    function testFuzz_VaultDepositWithdraw(uint256 assets) public {
        assets = bound(assets, 1, 100_000 ether);
        vm.startPrank(alice);
        token0.approve(address(vault), assets);
        uint256 shares = vault.deposit(assets, alice);
        uint256 back = vault.redeem(shares, alice, alice);
        assertApproxEqAbs(back, assets, 1);
        vm.stopPrank();
    }

    function testFuzz_GovernanceVotes(uint256 delegateAmt) public {
        delegateAmt = bound(delegateAmt, 1e16, 100_000 ether);
        vm.prank(address(treasury));
        govToken.transfer(alice, delegateAmt);
        vm.prank(alice);
        govToken.delegate(alice);
        vm.warp(block.timestamp + 1);
        assertGe(govToken.getVotes(alice), delegateAmt);
    }

    function testFuzz_LendingDeposit(uint256 col) public {
        col = bound(col, 1 ether, 50_000 ether);
        vm.startPrank(alice);
        token0.approve(address(lending), col);
        lending.depositCollateral(col);
        assertEq(lending.collateralBalance(alice), col);
        vm.stopPrank();
    }

    function testFuzz_AssemblyMatchesSolidity(uint256 x, uint256 y, uint256 d) public {
        d = bound(d, 1, type(uint128).max);
        x = bound(x, 0, type(uint128).max);
        y = bound(y, 0, type(uint128).max);
        assertEq(AssemblyMath.mulDivAssembly(x, y, d), AssemblyMath.mulDivSolidity(x, y, d));
    }

    function testFuzz_OraclePricePositive(int256 ans) public {
        ans = int256(bound(uint256(ans), 1, type(uint128).max));
        vm.prank(admin);
        feed.setAnswer(ans);
        (uint256 p,) = oracle.latestPrice();
        assertGt(p, 0);
    }

    function testFuzz_AMMKConstant(uint256 a0, uint256 a1) public {
        a0 = bound(a0, 100 ether, 5000 ether);
        a1 = bound(a1, 100 ether, 5000 ether);
        (uint256 r0, uint256 r1) = amm.getReserves();
        uint256 kBefore = r0 * r1;
        vm.startPrank(bob);
        token0.approve(address(amm), a0);
        amm.swapExactTokensForTokens(a0, 0, true, bob);
        (uint256 r0a, uint256 r1a) = amm.getReserves();
        assertGe(r0a * r1a, kBefore);
        token1.approve(address(amm), a1);
        amm.swapExactTokensForTokens(a1, 0, false, bob);
        (uint256 r0b, uint256 r1b) = amm.getReserves();
        assertGe(r0b * r1b, r0a * r1a);
        vm.stopPrank();
    }

    function testFuzz_TreasuryPending(uint256 amt) public {
        amt = bound(amt, 1, 1_000_000 ether);
        vm.prank(admin);
        treasury.scheduleWithdrawal(address(token0), bob, amt);
        assertEq(treasury.pendingWithdrawals(address(token0), bob), amt);
    }

    function testFuzz_VaultMint(uint256 shares) public {
        shares = bound(shares, 1, 10_000 ether);
        vm.startPrank(alice);
        token0.approve(address(vault), type(uint256).max);
        vault.mint(shares, alice);
        assertGe(vault.balanceOf(alice), shares);
        vm.stopPrank();
    }

    function testFuzz_RepayBounded(uint256 repayAmt) public {
        vm.startPrank(alice);
        token0.approve(address(lending), 5000 ether);
        lending.depositCollateral(5000 ether);
        lending.borrow(100 ether);
        repayAmt = bound(repayAmt, 1, 100 ether);
        token1.approve(address(lending), repayAmt);
        lending.repay(repayAmt);
        assertLe(lending.borrowBalance(alice), 100 ether);
        vm.stopPrank();
    }
}
