// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @notice Protocol treasury controlled by Timelock (pull-over-push withdrawals).
contract Treasury is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant SPENDER_ROLE = keccak256("SPENDER_ROLE");

    mapping(address => mapping(address => uint256)) public pendingWithdrawals;

    event WithdrawalScheduled(address indexed token, address indexed to, uint256 amount);
    event WithdrawalClaimed(address indexed token, address indexed to, uint256 amount);

    constructor(address timelock) {
        _grantRole(DEFAULT_ADMIN_ROLE, timelock);
        _grantRole(SPENDER_ROLE, timelock);
    }

    function scheduleWithdrawal(address token, address to, uint256 amount) external onlyRole(SPENDER_ROLE) {
        pendingWithdrawals[token][to] += amount;
        emit WithdrawalScheduled(token, to, amount);
    }

    function claimWithdrawal(address token) external {
        uint256 amount = pendingWithdrawals[token][msg.sender];
        require(amount > 0, "nothing pending");
        pendingWithdrawals[token][msg.sender] = 0;
        IERC20(token).safeTransfer(msg.sender, amount);
        emit WithdrawalClaimed(token, msg.sender, amount);
    }

    receive() external payable {}
}
