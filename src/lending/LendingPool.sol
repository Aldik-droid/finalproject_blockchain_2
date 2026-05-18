// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {PriceOracle} from "../oracle/PriceOracle.sol";

/// @notice Simple over-collateralized lending pool with LTV, health factor, and liquidation.
contract LendingPool is ReentrancyGuard, AccessControl, Pausable {
    using SafeERC20 for IERC20;

    bytes32 public constant RISK_ADMIN_ROLE = keccak256("RISK_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    IERC20 public immutable collateralToken;
    IERC20 public immutable borrowToken;
    PriceOracle public immutable priceOracle;

    uint256 public ltvBps = 7500; // 75%
    uint256 public liquidationThresholdBps = 8000;
    uint256 public liquidationBonusBps = 500;
    uint256 public constant BPS = 10_000;

    mapping(address => uint256) public collateralBalance;
    mapping(address => uint256) public borrowBalance;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event Liquidated(address indexed user, address indexed liquidator, uint256 debtRepaid, uint256 collateralSeized);

    error InsufficientCollateral();
    error UnhealthyPosition();
    error HealthyPosition();
    error ZeroAmount();

    constructor(address collateral_, address borrow_, address oracle_, address admin) {
        collateralToken = IERC20(collateral_);
        borrowToken = IERC20(borrow_);
        priceOracle = PriceOracle(oracle_);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(RISK_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setLtv(uint256 newLtvBps) external onlyRole(RISK_ADMIN_ROLE) {
        require(newLtvBps <= liquidationThresholdBps, "LTV too high");
        ltvBps = newLtvBps;
    }

    function depositCollateral(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        collateralBalance[msg.sender] += amount;
        collateralToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposited(msg.sender, amount);
    }

    function withdrawCollateral(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        collateralBalance[msg.sender] -= amount;
        if (healthFactor(msg.sender) < 1e18) revert UnhealthyPosition();
        collateralToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function borrow(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        borrowBalance[msg.sender] += amount;
        if (healthFactor(msg.sender) < 1e18) revert UnhealthyPosition();
        borrowToken.safeTransfer(msg.sender, amount);
        emit Borrowed(msg.sender, amount);
    }

    function repay(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        uint256 debt = borrowBalance[msg.sender];
        uint256 pay = amount > debt ? debt : amount;
        borrowBalance[msg.sender] = debt - pay;
        borrowToken.safeTransferFrom(msg.sender, address(this), pay);
        emit Repaid(msg.sender, pay);
    }

    function liquidate(address user, uint256 debtToCover) external nonReentrant whenNotPaused {
        if (healthFactor(user) >= 1e18) revert HealthyPosition();
        uint256 debt = borrowBalance[user];
        uint256 repayAmount = debtToCover > debt ? debt : debtToCover;
        borrowBalance[user] = debt - repayAmount;

        (uint256 price,) = priceOracle.latestPrice();
        uint256 bonus = (repayAmount * (BPS + liquidationBonusBps)) / BPS;
        uint256 collateralToSeize = (bonus * 1e8) / price;
        if (collateralToSeize > collateralBalance[user]) collateralToSeize = collateralBalance[user];
        collateralBalance[user] -= collateralToSeize;

        borrowToken.safeTransferFrom(msg.sender, address(this), repayAmount);
        collateralToken.safeTransfer(msg.sender, collateralToSeize);
        emit Liquidated(user, msg.sender, repayAmount, collateralToSeize);
    }

    function healthFactor(address user) public view returns (uint256) {
        uint256 debt = borrowBalance[user];
        if (debt == 0) return type(uint256).max;
        (uint256 price,) = priceOracle.latestPrice();
        uint256 collateralValue = (collateralBalance[user] * price) / 1e8;
        uint256 maxBorrow = (collateralValue * liquidationThresholdBps) / BPS;
        return (maxBorrow * 1e18) / debt;
    }

    function maxBorrowable(address user) public view returns (uint256) {
        (uint256 price,) = priceOracle.latestPrice();
        uint256 collateralValue = (collateralBalance[user] * price) / 1e8;
        return (collateralValue * ltvBps) / BPS;
    }
}
