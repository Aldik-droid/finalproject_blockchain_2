// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice ERC-4626 yield vault with linear yield accrual from an external strategy balance.
contract YieldVault4626 is ERC4626, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant YIELD_MANAGER_ROLE = keccak256("YIELD_MANAGER_ROLE");

    uint256 public yieldRateBps = 500; // 5% APR simplified
    uint256 public lastAccrual;
    uint256 public strategyYield;

    event YieldAccrued(uint256 amount);
    event YieldDeposited(uint256 amount);

    constructor(IERC20 asset_, address admin)
        ERC4626(asset_)
        ERC20("DeFi Super Yield Vault", "dsyVault")
    {
        lastAccrual = block.timestamp;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(YIELD_MANAGER_ROLE, admin);
    }

    function depositYield(uint256 amount) external onlyRole(YIELD_MANAGER_ROLE) {
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), amount);
        strategyYield += amount;
        emit YieldDeposited(amount);
    }

    function accrueYield() public {
        uint256 elapsed = block.timestamp - lastAccrual;
        if (elapsed == 0) return;
        uint256 assets = totalAssets();
        uint256 accrued = (assets * yieldRateBps * elapsed) / (BPS * 365 days);
        if (accrued > strategyYield) accrued = strategyYield;
        if (accrued > 0) {
            strategyYield -= accrued;
            lastAccrual = block.timestamp;
            emit YieldAccrued(accrued);
        }
    }

    uint256 private constant BPS = 10_000;

    function totalAssets() public view override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this)) + strategyYield;
    }

    function deposit(uint256 assets, address receiver) public override nonReentrant returns (uint256) {
        accrueYield();
        return super.deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver) public override nonReentrant returns (uint256) {
        accrueYield();
        return super.mint(shares, receiver);
    }

    function withdraw(uint256 assets, address receiver, address owner) public override nonReentrant returns (uint256) {
        accrueYield();
        return super.withdraw(assets, receiver, owner);
    }

    function redeem(uint256 shares, address receiver, address owner) public override nonReentrant returns (uint256) {
        accrueYield();
        return super.redeem(shares, receiver, owner);
    }
}
