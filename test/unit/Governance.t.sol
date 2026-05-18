// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseTest} from "../helpers/BaseTest.sol";
import {DeFiGovernor} from "../../src/governance/DeFiGovernor.sol";

contract GovernanceTest is BaseTest {
    function test_VotingDelay() public view {
        assertEq(governor.votingDelay(), 1 days);
    }

    function test_VotingPeriod() public view {
        assertEq(governor.votingPeriod(), 7 days);
    }

    function test_Quorum() public view {
        assertEq(governor.quorumNumerator(), 4);
    }

    function test_ProposalThreshold() public view {
        assertEq(governor.proposalThreshold(), 1e16);
    }

    function test_TimelockDelay() public view {
        assertEq(timelock.getMinDelay(), 2 days);
    }

    function test_DelegateVotingPower() public {
        vm.prank(address(treasury));
        govToken.delegate(alice);
        vm.warp(block.timestamp + 1);
        assertGt(govToken.getVotes(alice), 0);
    }

    function test_ProposeVoteQueueExecute() public {
        address proposer = address(treasury);
        vm.startPrank(admin);
        lending.grantRole(lending.RISK_ADMIN_ROLE(), address(timelock));
        vm.stopPrank();

        vm.prank(proposer);
        govToken.delegate(proposer);
        vm.roll(block.number + 1);

        address[] memory targets = new address[](1);
        targets[0] = address(lending);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(lending.setLtv.selector, 7400);

        vm.prank(proposer);
        uint256 pid = governor.propose(targets, values, calldatas, "lower ltv");

        uint256 startBlock = block.number;
        vm.roll(startBlock + governor.votingDelay() + 1);
        vm.prank(proposer);
        governor.castVote(pid, 1);

        vm.roll(startBlock + governor.votingDelay() + governor.votingPeriod() + 2);
        bytes32 descHash = keccak256("lower ltv");
        governor.queue(targets, values, calldatas, descHash);

        vm.warp(block.timestamp + timelock.getMinDelay() + 1);
        governor.execute(targets, values, calldatas, descHash);
        assertEq(lending.ltvBps(), 7400);
    }

    function test_Clock() public view {
        assertGt(governor.clock(), 0);
    }
}
