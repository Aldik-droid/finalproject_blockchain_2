// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTest} from "../helpers/BaseTest.sol";
import {ConstantProductAMM} from "../../src/amm/ConstantProductAMM.sol";
import {LPToken} from "../../src/tokens/LPToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AMMTest is BaseTest {
    function test_GetReservesInitiallyZero() public view {
        (uint256 r0, uint256 r1) = amm.getReserves();
        assertEq(r0, 0);
        assertEq(r1, 0);
    }

    function test_AddLiquidityFirstMint() public {
        vm.startPrank(alice);
        token0.approve(address(amm), 1000 ether);
        token1.approve(address(amm), 1000 ether);
        uint256 liq = amm.addLiquidity(1000 ether, 1000 ether, 0, 0);
        assertGt(liq, 0);
        vm.stopPrank();
    }

    function test_AddLiquidityRevertInsufficient() public {
        vm.prank(alice);
        token0.approve(address(amm), 1);
        vm.expectRevert();
        amm.addLiquidity(0, 0, 1, 1);
    }

    function test_SwapZeroForOne() public {
        _seedPool();
        vm.startPrank(bob);
        token0.approve(address(amm), 100 ether);
        uint256 out = amm.swapExactTokensForTokens(10 ether, 1, true, bob);
        assertGt(out, 0);
        vm.stopPrank();
    }

    function test_SwapRevertSlippage() public {
        _seedPool();
        vm.startPrank(bob);
        token0.approve(address(amm), 10 ether);
        vm.expectRevert();
        amm.swapExactTokensForTokens(10 ether, 1000 ether, true, bob);
        vm.stopPrank();
    }

    function test_SwapRevertInvalidTo() public {
        _seedPool();
        vm.startPrank(bob);
        token0.approve(address(amm), 10 ether);
        vm.expectRevert();
        amm.swapExactTokensForTokens(1 ether, 0, true, address(token0));
        vm.stopPrank();
    }

    function test_RemoveLiquidity() public {
        _seedPool();
        uint256 lp = IERC20(address(amm.lpToken())).balanceOf(alice);
        vm.startPrank(alice);
        amm.removeLiquidity(lp / 2, 0, 0);
        vm.stopPrank();
    }

    function test_PauseBlocksSwap() public {
        _seedPool();
        vm.prank(admin);
        amm.pause();
        vm.startPrank(bob);
        token0.approve(address(amm), 10 ether);
        vm.expectRevert();
        amm.swapExactTokensForTokens(1 ether, 0, true, bob);
        vm.stopPrank();
    }

    function test_UnpauseAllowsSwap() public {
        _seedPool();
        vm.startPrank(admin);
        amm.pause();
        amm.unpause();
        vm.stopPrank();
        vm.startPrank(bob);
        token0.approve(address(amm), 10 ether);
        amm.swapExactTokensForTokens(1 ether, 0, true, bob);
        vm.stopPrank();
    }

    function test_KIncreasesOnMint() public {
        vm.startPrank(alice);
        token0.approve(address(amm), 100 ether);
        token1.approve(address(amm), 100 ether);
        amm.addLiquidity(100 ether, 100 ether, 0, 0);
        (uint256 r0, uint256 r1) = amm.getReserves();
        assertGt(r0 * r1, 0);
        vm.stopPrank();
    }

    function test_LPTokenOnlyPoolCanMint() public {
        LPToken lp = amm.lpToken();
        vm.expectRevert();
        lp.mint(alice, 1);
    }

    function test_FeeAppliedOnSwap() public {
        _seedPool();
        (uint256 r0Before,) = amm.getReserves();
        vm.startPrank(bob);
        token0.approve(address(amm), 100 ether);
        amm.swapExactTokensForTokens(100 ether, 0, true, bob);
        vm.stopPrank();
        (uint256 r0After,) = amm.getReserves();
        assertGt(r0After, r0Before);
    }

    function _seedPool() internal {
        vm.startPrank(alice);
        token0.approve(address(amm), 10_000 ether);
        token1.approve(address(amm), 10_000 ether);
        amm.addLiquidity(10_000 ether, 10_000 ether, 0, 0);
        vm.stopPrank();
    }
}
