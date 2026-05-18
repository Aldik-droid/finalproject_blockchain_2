// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTest} from "../helpers/BaseTest.sol";
import {ProtocolRegistryV2} from "../../src/upgradeable/ProtocolRegistryV2.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {ConstantProductAMM} from "../../src/amm/ConstantProductAMM.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Additional unit tests to raise `src/` line coverage above 90%.
contract CoverageBoostTest is BaseTest {
    function test_GovTokenTransferUpdatesBalance() public {
        vm.prank(address(treasury));
        govToken.transfer(alice, 10_000 ether);
        assertEq(govToken.balanceOf(alice), 10_000 ether);
    }

    function test_GovTokenPermit() public {
        uint256 ownerKey = 0xBEEF;
        address owner = vm.addr(ownerKey);
        vm.prank(address(treasury));
        govToken.transfer(owner, 100 ether);

        uint256 deadline = block.timestamp + 1 days;
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                owner,
                bob,
                50 ether,
                govToken.nonces(owner),
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", govToken.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, digest);
        govToken.permit(owner, bob, 50 ether, deadline, v, r, s);
        assertEq(govToken.allowance(owner, bob), 50 ether);
    }

    function test_LPNftSupportsInterface() public view {
        assertTrue(lpNft.supportsInterface(0x80ac58cd)); // ERC721
        assertTrue(lpNft.supportsInterface(0x01ffc9a7)); // ERC165
    }

    function test_MockFeedMetadataAndRoundData() public view {
        assertEq(feed.description(), "Mock ETH/USD");
        assertEq(feed.version(), 1);
        (uint80 roundId, int256 ans, uint256 startedAt, uint256 updatedAt_, uint80 answeredInRound) =
            feed.latestRoundData();
        assertEq(roundId, 1);
        assertEq(ans, 2000e8);
        assertGt(startedAt, 0);
        assertGt(updatedAt_, 0);
        assertEq(answeredInRound, 1);
    }

    function test_RegistryV2SetOracle() public {
        ProtocolRegistryV2 v2Impl = new ProtocolRegistryV2();
        vm.prank(admin);
        UUPSUpgradeable(address(registry)).upgradeToAndCall(
            address(v2Impl), abi.encodeWithSelector(ProtocolRegistryV2.initializeV2.selector, address(oracle))
        );
        ProtocolRegistryV2 reg2 = ProtocolRegistryV2(address(registry));
        vm.prank(admin);
        reg2.setOracle(bob);
        assertEq(reg2.priceOracle(), bob);
    }

    function test_GovernorStateAndQueuing() public view {
        assertTrue(governor.proposalNeedsQueuing(0));
    }

    function test_SwapOneForZero() public {
        _seedAmm();
        vm.startPrank(bob);
        token1.approve(address(amm), 50 ether);
        uint256 out = amm.swapExactTokensForTokens(10 ether, 0, false, bob);
        assertGt(out, 0);
        vm.stopPrank();
    }

    function test_AddLiquiditySlippageRevert() public {
        _seedAmm();
        vm.startPrank(bob);
        token0.approve(address(amm), 100 ether);
        token1.approve(address(amm), 100 ether);
        vm.expectRevert(ConstantProductAMM.InsufficientOutput.selector);
        amm.addLiquidity(100 ether, 100 ether, 0, type(uint256).max);
        vm.stopPrank();
    }

    function test_AddLiquidityAmount1OptimalBranch() public {
        _seedAmm();
        vm.startPrank(bob);
        token0.approve(address(amm), 5000 ether);
        token1.approve(address(amm), 50 ether);
        uint256 liq = amm.addLiquidity(5000 ether, 50 ether, 0, 0);
        assertGt(liq, 0);
        vm.stopPrank();
    }

    function test_RemoveLiquiditySlippageRevert() public {
        _seedAmm();
        uint256 lp = IERC20(address(amm.lpToken())).balanceOf(alice);
        vm.prank(alice);
        vm.expectRevert(ConstantProductAMM.InsufficientOutput.selector);
        amm.removeLiquidity(lp, type(uint256).max, type(uint256).max);
    }

    function _seedAmm() internal {
        vm.startPrank(alice);
        token0.approve(address(amm), 10_000 ether);
        token1.approve(address(amm), 10_000 ether);
        amm.addLiquidity(10_000 ether, 10_000 ether, 0, 0);
        vm.stopPrank();
    }

    function test_LendingUnpauseAndRepayPartial() public {
        vm.startPrank(alice);
        token0.approve(address(lending), 500 ether);
        lending.depositCollateral(500 ether);
        lending.borrow(100 ether);
        token1.approve(address(lending), 200 ether);
        lending.repay(200 ether);
        vm.stopPrank();
        assertEq(lending.borrowBalance(alice), 0);
        vm.startPrank(admin);
        lending.pause();
        lending.unpause();
        vm.stopPrank();
    }

    function test_LendingSetLtvTooHighReverts() public {
        vm.prank(admin);
        vm.expectRevert();
        lending.setLtv(9000);
    }

    function test_GovernorCancelProposal() public {
        address proposer = address(treasury);
        vm.prank(proposer);
        govToken.delegate(proposer);
        vm.roll(block.number + 1);

        address[] memory targets = new address[](1);
        targets[0] = address(lending);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(lending.setLtv.selector, 7500);

        vm.prank(proposer);
        uint256 pid = governor.propose(targets, values, calldatas, "cancel me");
        bytes32 descHash = keccak256(bytes("cancel me"));

        vm.prank(proposer);
        governor.cancel(targets, values, calldatas, descHash);
        assertEq(uint8(governor.state(pid)), uint8(IGovernor.ProposalState.Canceled));
    }
}
