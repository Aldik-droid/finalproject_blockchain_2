// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @dev Educational access-control case study (unguarded admin vs AccessControl).
contract AccessControlVulnerable {
    address public owner;
    uint256 public feeBps = 30;

    constructor() {
        owner = msg.sender;
    }

    /// @notice Missing onlyOwner — anyone can change fees.
    function setFee(uint256 newFee) external {
        feeBps = newFee;
    }
}

contract AccessControlFixed is AccessControl {
    bytes32 public constant FEE_ADMIN_ROLE = keccak256("FEE_ADMIN_ROLE");
    uint256 public feeBps = 30;

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(FEE_ADMIN_ROLE, admin);
    }

    function setFee(uint256 newFee) external onlyRole(FEE_ADMIN_ROLE) {
        feeBps = newFee;
    }
}
