// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTest} from "../helpers/BaseTest.sol";
import {ProtocolRegistryV2} from "../../src/upgradeable/ProtocolRegistryV2.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TreasuryUpgradeTest is BaseTest {
    function test_TreasuryScheduleClaim() public {
        vm.startPrank(admin);
        treasury.scheduleWithdrawal(address(token0), alice, 10 ether);
        vm.stopPrank();
        vm.prank(admin);
        token0.mint(address(treasury), 10 ether);
        vm.prank(alice);
        treasury.claimWithdrawal(address(token0));
        assertEq(token0.balanceOf(alice), 1_000_000 ether + 10 ether);
    }

    function test_TreasuryClaimRevertNothing() public {
        vm.prank(alice);
        vm.expectRevert();
        treasury.claimWithdrawal(address(token0));
    }

    function test_RegistryV1Addresses() public view {
        assertEq(registry.amm(), address(amm));
        assertEq(registry.lendingPool(), address(lending));
        assertEq(registry.vault(), address(vault));
    }

    function test_UpgradeToV2() public {
        ProtocolRegistryV2 v2Impl = new ProtocolRegistryV2();
        vm.prank(admin);
        UUPSUpgradeable(address(registry)).upgradeToAndCall(
            address(v2Impl), abi.encodeWithSelector(ProtocolRegistryV2.initializeV2.selector, address(oracle))
        );
        ProtocolRegistryV2 reg2 = ProtocolRegistryV2(address(registry));
        assertEq(reg2.registryVersion(), 2);
        assertEq(reg2.priceOracle(), address(oracle));
    }

    function test_RegistrySetAmm() public {
        vm.prank(admin);
        registry.setAmm(bob);
        assertEq(registry.amm(), bob);
    }
}
