// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {DeFiGovernor} from "../src/governance/DeFiGovernor.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {Treasury} from "../src/Treasury.sol";

/// @notice Post-deployment verification — outputs must be checked into repo.
contract VerifyDeployment is Script {
    function run() external view {
        address timelock = vm.envAddress("TIMELOCK");
        address governor = vm.envAddress("GOVERNOR");
        address treasury = vm.envAddress("TREASURY");

        TimelockController tl = TimelockController(payable(timelock));
        DeFiGovernor gov = DeFiGovernor(payable(governor));
        Treasury tr = Treasury(payable(treasury));

        require(tl.getMinDelay() == 2 days, "timelock delay");
        require(gov.votingDelay() == 1 days, "voting delay");
        require(gov.votingPeriod() == 7 days, "voting period");
        require(gov.quorumNumerator() == 4, "quorum");
        require(tr.hasRole(tr.DEFAULT_ADMIN_ROLE(), timelock), "treasury owner");

        console2.log("VERIFICATION_PASSED");
    }
}
