// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @dev Educational reentrancy case study (before/after) — see test/SecurityCaseStudies.t.sol.
contract ReentrancyVulnerableVault {
    mapping(address => uint256) public balances;

    function deposit(address token, uint256 amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
    }

    function withdraw(address token, uint256 amount) external {
        require(balances[msg.sender] >= amount, "bal");
        (bool ok,) = msg.sender.call(abi.encodeWithSignature("onWithdraw()"));
        ok;
        balances[msg.sender] -= amount;
        IERC20(token).transfer(msg.sender, amount);
    }
}

contract ReentrancyFixedVault is ReentrancyGuard {
    mapping(address => uint256) public balances;

    function deposit(address token, uint256 amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
    }

    function withdraw(address token, uint256 amount) external nonReentrant {
        require(balances[msg.sender] >= amount, "bal");
        balances[msg.sender] -= amount;
        IERC20(token).transfer(msg.sender, amount);
    }
}
