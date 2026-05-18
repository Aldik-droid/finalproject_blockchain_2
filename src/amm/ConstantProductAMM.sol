// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {LPToken} from "../tokens/LPToken.sol";

/// @notice Constant-product AMM (x·y=k) with 0.3% swap fee and LP tokens.
contract ConstantProductAMM is ReentrancyGuard, Pausable, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 public constant FEE_NUMERATOR = 997;
    uint256 public constant FEE_DENOMINATOR = 1000;

    IERC20 public immutable token0;
    IERC20 public immutable token1;
    LPToken public immutable lpToken;

    uint256 public reserve0;
    uint256 public reserve1;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1, uint256 liquidity);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, uint256 liquidity);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);

    error InsufficientLiquidity();
    error InsufficientOutput();
    error InsufficientInput();
    error InvalidTo();
    error KInvariantViolated();

    constructor(address token0_, address token1_, address admin) {
        token0 = IERC20(token0_);
        token1 = IERC20(token1_);
        lpToken = new LPToken("DeFi Super LP", "DSLP", address(this));
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function getReserves() external view returns (uint256, uint256) {
        return (reserve0, reserve1);
    }

    function addLiquidity(uint256 amount0Desired, uint256 amount1Desired, uint256 amount0Min, uint256 amount1Min)
        external
        nonReentrant
        whenNotPaused
        returns (uint256 liquidity)
    {
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        if (_reserve0 == 0 && _reserve1 == 0) {
            liquidity = _sqrt(amount0Desired * amount1Desired);
            if (liquidity == 0) revert InsufficientLiquidity();
        } else {
            uint256 amount1Optimal = (amount0Desired * _reserve1) / _reserve0;
            if (amount1Optimal <= amount1Desired) {
                if (amount1Optimal < amount1Min) revert InsufficientOutput();
                liquidity = (amount0Desired * lpToken.totalSupply()) / _reserve0;
            } else {
                uint256 amount0Optimal = (amount1Desired * _reserve0) / _reserve1;
                if (amount0Optimal < amount0Min) revert InsufficientOutput();
                liquidity = (amount1Desired * lpToken.totalSupply()) / _reserve1;
                amount0Desired = amount0Optimal;
                amount1Desired = amount1Desired;
            }
        }
        if (liquidity == 0) revert InsufficientLiquidity();

        token0.safeTransferFrom(msg.sender, address(this), amount0Desired);
        token1.safeTransferFrom(msg.sender, address(this), amount1Desired);

        reserve0 = _reserve0 + amount0Desired;
        reserve1 = _reserve1 + amount1Desired;
        lpToken.mint(msg.sender, liquidity);

        emit Mint(msg.sender, amount0Desired, amount1Desired, liquidity);
    }

    function removeLiquidity(uint256 liquidity, uint256 amount0Min, uint256 amount1Min)
        external
        nonReentrant
        whenNotPaused
        returns (uint256 amount0, uint256 amount1)
    {
        uint256 _totalSupply = lpToken.totalSupply();
        amount0 = (liquidity * reserve0) / _totalSupply;
        amount1 = (liquidity * reserve1) / _totalSupply;
        if (amount0 < amount0Min || amount1 < amount1Min) revert InsufficientOutput();

        lpToken.burn(msg.sender, liquidity);
        reserve0 -= amount0;
        reserve1 -= amount1;

        token0.safeTransfer(msg.sender, amount0);
        token1.safeTransfer(msg.sender, amount1);

        emit Burn(msg.sender, amount0, amount1, liquidity);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        bool zeroForOne,
        address to
    ) external nonReentrant whenNotPaused returns (uint256 amountOut) {
        if (to == address(token0) || to == address(token1)) revert InvalidTo();

        (IERC20 tokenIn, IERC20 tokenOut, uint256 reserveIn, uint256 reserveOut) = zeroForOne
            ? (token0, token1, reserve0, reserve1)
            : (token1, token0, reserve1, reserve0);

        tokenIn.safeTransferFrom(msg.sender, address(this), amountIn);
        uint256 amountInWithFee = (amountIn * FEE_NUMERATOR) / FEE_DENOMINATOR;
        amountOut = (amountInWithFee * reserveOut) / (reserveIn + amountInWithFee);
        if (amountOut < amountOutMin) revert InsufficientOutput();

        if (zeroForOne) {
            reserve0 = reserveIn + amountIn;
            reserve1 = reserveOut - amountOut;
        } else {
            reserve1 = reserveIn + amountIn;
            reserve0 = reserveOut - amountOut;
        }

        _assertKInvariant();
        tokenOut.safeTransfer(to, amountOut);
        emit Swap(msg.sender, zeroForOne ? amountIn : 0, zeroForOne ? 0 : amountIn, zeroForOne ? 0 : amountOut, zeroForOne ? amountOut : 0, to);
    }

    function _assertKInvariant() internal view {
        if (reserve0 * reserve1 < uint256(reserve0) * uint256(reserve1)) revert KInvariantViolated();
    }

    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y == 0) return 0;
        z = y;
        uint256 x = (y >> 1) + 1;
        while (x < z) {
            z = x;
            x = (y / x + x) >> 1;
        }
    }
}
