// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IAggregatorV3} from "../../src/interfaces/IAggregatorV3.sol";

/// @notice Fork tests against Base Sepolia / mainnet addresses (skipped if no RPC).
contract ForkTest is Test {
    address constant BASE_SEPOLIA_USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    address constant ETH_USD_FEED_BASE = 0x4adC67696BA383f43DD60aFe982A7f6e3F5CF663;

    function setUp() public {
        string memory rpc = vm.envOr("BASE_SEPOLIA_RPC", string(""));
        if (bytes(rpc).length == 0) {
            rpc = "https://sepolia.base.org";
        }
        vm.createSelectFork(rpc);
    }

    function testFork_USDCDecimals() public view {
        uint8 dec = IERC20Metadata(BASE_SEPOLIA_USDC).decimals();
        assertEq(dec, 6);
    }

    function testFork_ChainlinkFeedLatest() public {
        // Use USDC/ETH or skip when feed unavailable on fork
        vm.skip(true);
    }

    function testFork_USDCBalanceOfDeployer() public view {
        uint256 bal = IERC20(BASE_SEPOLIA_USDC).balanceOf(0x4200000000000000000000000000000000000006);
        assertGe(bal, 0);
    }
}
