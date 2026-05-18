# Coverage Report

**Command:** `forge coverage --report summary`  
**Scope:** `src/` only (`no_match_coverage` excludes `script/` and `test/` in `foundry.toml`)  
**Date:** May 2026 · repository HEAD

## Summary

| Metric | Result | Requirement (BChT2 PDF) |
|--------|--------|-------------------------|
| Line coverage (`src/`) | **99.38%** (321/323) | ≥ 90% |
| Statement coverage | 97.18% (310/319) | — |
| Branch coverage | 75.47% (40/53) | — |
| Function coverage | 100.00% (81/81) | — |

## Per-contract line coverage

| Contract | Line % |
|----------|--------|
| ConstantProductAMM | 97.06% |
| LendingPool | 100.00% |
| YieldVault4626 | 100.00% |
| DeFiGovernor | 100.00% |
| DeFiGovToken | 100.00% |
| PriceOracle | 100.00% |
| PoolFactory | 100.00% |
| ProtocolRegistry V1/V2 | 100.00% |
| Treasury | 100.00% |
| Security case studies | 100.00% |

## Test counts

| Category | Count | Minimum |
|----------|-------|---------|
| Total tests | **109** (108 pass, 1 fork skip) | 80 |
| Unit | 70+ | 50 |
| Fuzz | 10 | 10 |
| Invariant | 5+ | 5 |
| Fork | 3 | 3 |

## Reproduce

```bash
forge test
forge coverage --report summary
```

Full terminal output is archived in [`docs/terminal-outputs/forge-test.txt`](terminal-outputs/forge-test.txt) and [`docs/terminal-outputs/forge-coverage.txt`](terminal-outputs/forge-coverage.txt).
