// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice LP share token for a single AMM pair.
contract LPToken is ERC20 {
    address public immutable pool;

    constructor(string memory name_, string memory symbol_, address pool_) ERC20(name_, symbol_) {
        pool = pool_;
    }

    modifier onlyPool() {
        require(msg.sender == pool, "LPToken: not pool");
        _;
    }

    function mint(address to, uint256 amount) external onlyPool {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyPool {
        _burn(from, amount);
    }
}
