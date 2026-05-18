// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Treasury} from "../src/Treasury.sol";

/// @notice One-time fix: grant timelock treasury admin (deploy v1 passed deployer to Treasury constructor).
contract FixTreasuryAdmin is Script {
    function run() external {
        Treasury treasury = Treasury(payable(vm.envAddress("TREASURY")));
        address timelock = vm.envAddress("TIMELOCK");

        vm.startBroadcast();
        if (!treasury.hasRole(treasury.DEFAULT_ADMIN_ROLE(), timelock)) {
            treasury.grantRole(treasury.DEFAULT_ADMIN_ROLE(), timelock);
        }
        if (treasury.hasRole(treasury.DEFAULT_ADMIN_ROLE(), msg.sender)) {
            treasury.renounceRole(treasury.DEFAULT_ADMIN_ROLE(), msg.sender);
        }
        vm.stopBroadcast();
    }
}
