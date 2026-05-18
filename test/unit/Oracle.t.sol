// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTest} from "../helpers/BaseTest.sol";
import {PriceOracle} from "../../src/oracle/PriceOracle.sol";

contract OracleTest is BaseTest {
    function test_LatestPrice() public view {
        (uint256 price,) = oracle.latestPrice();
        assertEq(price, 2000e8);
    }

    function test_StalePriceReverts() public {
        vm.warp(10_000);
        feed.setStale();
        vm.expectRevert(PriceOracle.StalePrice.selector);
        oracle.latestPrice();
    }

    function test_InvalidPriceReverts() public {
        vm.prank(admin);
        feed.setAnswer(-1);
        vm.expectRevert(PriceOracle.InvalidPrice.selector);
        oracle.latestPrice();
    }

    function test_FeedDecimals() public view {
        assertEq(feed.decimals(), 8);
    }

    function test_SetAnswerUpdates() public {
        vm.prank(admin);
        feed.setAnswer(3000e8);
        (uint256 p,) = oracle.latestPrice();
        assertEq(p, 3000e8);
    }

    function test_MaxStalenessImmutable() public view {
        assertEq(oracle.maxStaleness(), 3600);
    }
}
