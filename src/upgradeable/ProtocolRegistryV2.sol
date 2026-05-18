// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ProtocolRegistryV1} from "./ProtocolRegistryV1.sol";

/// @notice V2 adds oracle reference and version tag — documented V1 → V2 upgrade path.
contract ProtocolRegistryV2 is ProtocolRegistryV1 {
    address public priceOracle;
    uint256 public registryVersion;

    function initializeV2(address oracle_) external reinitializer(2) {
        priceOracle = oracle_;
        registryVersion = 2;
    }

    function setOracle(address oracle_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        priceOracle = oracle_;
    }
}
