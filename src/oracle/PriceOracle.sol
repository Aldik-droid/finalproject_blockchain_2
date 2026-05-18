// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAggregatorV3} from "../interfaces/IAggregatorV3.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @notice Oracle adapter with staleness guard (Oracle adapter pattern).
contract PriceOracle is AccessControl {
    bytes32 public constant ORACLE_ADMIN_ROLE = keccak256("ORACLE_ADMIN_ROLE");

    IAggregatorV3 public immutable feed;
    uint256 public immutable maxStaleness;

    error StalePrice();
    error InvalidPrice();

    event MaxStalenessUpdated(uint256 oldValue, uint256 newValue);

    constructor(address feed_, uint256 maxStaleness_, address admin) {
        feed = IAggregatorV3(feed_);
        maxStaleness = maxStaleness_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ORACLE_ADMIN_ROLE, admin);
    }

    function latestPrice() public view returns (uint256 price, uint256 updatedAt) {
        (, int256 answer,, uint256 ts,) = feed.latestRoundData();
        if (block.timestamp - ts > maxStaleness) revert StalePrice();
        if (answer <= 0) revert InvalidPrice();
        return (uint256(answer), ts);
    }
}
