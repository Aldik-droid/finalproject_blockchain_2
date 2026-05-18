// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/// @notice UUPS upgradeable registry — V1 stores core protocol addresses.
contract ProtocolRegistryV1 is Initializable, UUPSUpgradeable, AccessControlUpgradeable {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    address public amm;
    address public lendingPool;
    address public vault;
    address public treasury;

    /// @dev Storage gap for upgrade safety.
    uint256[46] private __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin, address amm_, address lending_, address vault_, address treasury_) external initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
        amm = amm_;
        lendingPool = lending_;
        vault = vault_;
        treasury = treasury_;
    }

    function _authorizeUpgrade(address) internal override onlyRole(UPGRADER_ROLE) {}

    function setAmm(address newAmm) external onlyRole(DEFAULT_ADMIN_ROLE) {
        amm = newAmm;
    }
}
