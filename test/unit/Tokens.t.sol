// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTest} from "../helpers/BaseTest.sol";

contract TokensTest is BaseTest {
    function test_GovTokenSupply() public view {
        assertEq(govToken.totalSupply(), 1_000_000 ether);
    }

    function test_GovTokenPermitDomain() public view {
        assertEq(govToken.name(), "DeFi Super Gov");
    }

    function test_ProtocolTokenMint() public {
        vm.prank(admin);
        token0.mint(alice, 100 ether);
        assertEq(token0.balanceOf(alice), 1_000_100 ether);
    }

    function test_ProtocolTokenMintUnauthorized() public {
        vm.prank(alice);
        vm.expectRevert();
        token0.mint(alice, 1 ether);
    }

    function test_LPNftMint() public {
        vm.startPrank(admin);
        lpNft.grantRole(lpNft.MINTER_ROLE(), admin);
        uint256 id = lpNft.mint(alice);
        vm.stopPrank();
        assertEq(lpNft.ownerOf(id), alice);
    }

    function test_LPNftMintUnauthorized() public {
        vm.prank(alice);
        vm.expectRevert();
        lpNft.mint(alice);
    }
}
