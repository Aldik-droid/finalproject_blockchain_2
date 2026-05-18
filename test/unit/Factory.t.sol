// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTest} from "../helpers/BaseTest.sol";
import {ProtocolToken} from "../../src/tokens/ProtocolToken.sol";

contract FactoryTest is BaseTest {
    ProtocolToken tA;
    ProtocolToken tB;

    function setUp() public override {
        super.setUp();
        vm.startPrank(admin);
        tA = new ProtocolToken(admin);
        tB = new ProtocolToken(admin);
        vm.stopPrank();
    }

    function test_CreatePool() public {
        vm.prank(admin);
        address pool = factory.createPool(address(tA), address(tB));
        assertTrue(pool != address(0));
        assertEq(factory.poolsLength(), 1);
    }

    function test_CreatePoolRevertDuplicate() public {
        vm.startPrank(admin);
        factory.createPool(address(tA), address(tB));
        vm.expectRevert();
        factory.createPool(address(tA), address(tB));
        vm.stopPrank();
    }

    function test_CreatePoolDeterministic() public {
        bytes32 salt = keccak256("salt1");
        vm.prank(admin);
        address p1 = factory.createPoolDeterministic(address(tA), address(tB), salt);
        assertTrue(p1 != address(0));
    }

    function test_GetPoolMapping() public {
        vm.prank(admin);
        address pool = factory.createPool(address(tA), address(tB));
        assertEq(factory.getPool(address(tA), address(tB)), pool);
    }

    function test_CreatePoolRevertIdentical() public {
        vm.prank(admin);
        vm.expectRevert();
        factory.createPool(address(tA), address(tA));
    }
}
