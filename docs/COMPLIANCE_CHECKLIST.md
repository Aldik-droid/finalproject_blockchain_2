# BChT2 Final Project — Compliance Checklist

Reference: **BChT2 Final Project PDF** (Option A — DeFi Super-App).  
Legend: ✅ Met · ⚠️ Partial / action required · ❌ Not met

## Deliverables

| Item | Status | Location |
|------|--------|----------|
| Foundry smart contracts | ✅ | `src/` |
| Test suite (unit/fuzz/invariant/fork) | ✅ | `test/` — 109 tests |
| React + Wagmi frontend | ✅ | `frontend/` |
| The Graph subgraph | ✅ | `subgraph/` |
| L2 deployment script | ✅ | `script/Deploy.s.sol` |
| Verified addresses on L2 | ⚠️ | Run Base Sepolia deploy (see below) |
| Security audit report (≥8 pp.) | ✅ | `docs/AUDIT_REPORT.md` |
| Architecture doc (≥6 pp.) | ✅ | `docs/ARCHITECTURE.md` |
| Gas report | ✅ | `docs/GAS_REPORT.md` |
| Coverage report in repo | ✅ | `docs/COVERAGE.md` |
| README | ✅ | `README.md` |
| Presentation | ✅ | `docs/PRESENTATION.md` |
| GitHub repository | ⚠️ | Init commit + push required |

## Mandatory technical (Section 3)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| UUPS upgradeable + V1→V2 path | ✅ | `ProtocolRegistryV1/V2`, `test/unit/TreasuryUpgrade.t.sol` |
| Factory CREATE + CREATE2 | ✅ | `PoolFactory`, `test/unit/Factory.t.sol` |
| Yul assembly benchmarked | ✅ | `AssemblyMath`, `test/unit/Assembly.t.sol` |
| ERC20Votes + Permit governance token | ✅ | `DeFiGovToken` |
| ERC-721 or ERC-1155 | ✅ | `LPPositionNFT` (ERC-721) |
| ERC-4626 vault + rounding tests | ✅ | `YieldVault4626`, `test/unit/Vault.t.sol` |
| AMM x·y=k, 0.3% fee, LP, slippage | ✅ | `ConstantProductAMM` |
| Chainlink + staleness | ✅ | `PriceOracle`, `MockChainlinkAggregator` |
| Subgraph ≥4 entities, ≥5 queries | ✅ | `subgraph/schema.graphql`, `subgraph/queries.md` |
| Governor + Timelock (1d/7d/4%/1%) | ✅ | `DeFiGovernor`, tests |
| Full propose→vote→queue→execute | ✅ | `test/unit/Governance.t.sol` |
| L2 deploy + verify | ⚠️ | Base Sepolia — **you must broadcast** |
| L1 vs L2 gas table | ✅ | `docs/GAS_REPORT.md` |
| CEI / ReentrancyGuard documented | ✅ | `docs/AUDIT_REPORT.md` |
| AccessControl on privileged functions | ✅ | All admin contracts |
| Slither 0 High / 0 Medium | ⚠️ | Run in CI / locally before submit |
| 2 vulnerability case studies + tests | ✅ | `src/security/*`, `test/unit/Security.t.sol` |
| ≥80 tests, ≥90% `src/` coverage | ✅ | 109 tests, 99.38% lines |
| Frontend: wallet, read state, 3 writes | ✅ | `frontend/src/App.tsx` |
| Governance UI + vote | ✅ | App.tsx |
| Subgraph data in UI | ✅ | `fetchRecentSwaps` |
| Error handling + wrong chain | ✅ | `errors.ts`, baseSepolia check |
| GitHub Actions CI | ✅ | `.github/workflows/ci.yml` |
| Reproducible deploy script | ✅ | `script/Deploy.s.sol` |
| Post-deploy verification script | ✅ | `script/VerifyDeployment.s.sol` |
| ≥5 design patterns documented | ✅ | `docs/ARCHITECTURE.md` §8 |

## Pre-submission actions (from course checklist)

1. **Deploy Base Sepolia** — `docs/terminal-outputs/deploy-base-sepolia-command.txt`
2. **Fill** `deployments/base-sepolia.json` (auto) and `frontend/.env`
3. **Subgraph** — `cd subgraph && graph deploy` → set `VITE_SUBGRAPH_URL`
4. **Push** repository to GitHub (required since Week 6)
5. **Slither** — attach clean run to audit appendix
6. **Print** audit + architecture if page count needed for defense
