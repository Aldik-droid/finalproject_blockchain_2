# Gas Optimization Report

## Assembly vs Solidity (`AssemblyMath`)

Benchmarked in `test/unit/Assembly.t.sol::test_GasBenchmark` — `mulDivAssembly` vs `mulDivSolidity` for identical inputs. Assembly path avoids Solidity overflow checks on intermediate multiply in tight loops; difference is small for single calls but documented for educational comparison.

## Optimizations applied

1. **Immutable oracle feed** in `PriceOracle` — saves SLOAD per price read.
2. **Packed reserves** in AMM — single storage slot not used (two uint256) but fee applied via `997/1000` constant math without external calls.
3. **ERC-4626** uses OZ implementation with `accrueYield` batched on user actions (lazy accrual).
4. **UUPS** registry — upgrade logic in implementation, minimal proxy overhead.

## L1 vs L2 comparison (Base Sepolia vs Ethereum mainnet estimates)

| Operation | Est. L1 gas | Est. L2 gas | Notes |
|-----------|-------------|-------------|-------|
| AMM swap | ~120k | ~120k | L2 cheaper in USD |
| Add liquidity | ~180k | ~180k | |
| Vault deposit | ~110k | ~110k | |
| Vault withdraw | ~95k | ~95k | |
| Lend borrow | ~85k | ~85k | |
| Liquidate | ~130k | ~130k | |
| Gov vote | ~75k | ~75k | |

L2 benefit is primarily **lower gas price** (ETH on L2), not lower gas units. Deploy on Base Sepolia for course requirement.

## Before/after

| Change | Before | After |
|--------|--------|-------|
| SafeERC20 in AMM | transfer | safeTransferFrom |
| Lending liquidation | unchecked | CEI + SafeERC20 |
