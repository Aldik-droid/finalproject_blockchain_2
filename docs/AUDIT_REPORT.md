# Security Audit Report — DeFi Super-App (Internal)

**Auditors:** Nursultan Tursunbaev, Zaki Sadaqatzada, Aldiyar Zharylkassyn  
**Client:** SE-2402 capstone (educational)  
**Version:** 1.0 · **Date:** May 2026  
**Scope commit:** repository `HEAD`  
**In scope:** `src/**/*.sol`  
**Out of scope:** `lib/`, `test/`, `frontend/`, third-party dependencies (trust OZ releases)

---

## 1. Executive summary

This report documents an **internal security review** of the DeFi Super-App: a constant-product AMM, collateralized lending pool, ERC-4626 vault, Chainlink-style price oracle, and OpenZeppelin Governor/Timelock governance on an L2 testnet target (Base Sepolia).

**Overall assessment:** For an educational capstone, the codebase follows modern Solidity practices (Solidity 0.8.24, OpenZeppelin 5.x, CEI, `SafeERC20`, `ReentrancyGuard`, role-based access). No Critical issues remain in scope after remediation of two deliberate case studies (reentrancy, access control). Before mainnet or graded submission, the team must confirm **Slither reports zero High and zero Medium** findings and complete **live L2 deployment verification**.

**Key strengths**

- Consistent use of `nonReentrant` on value-moving entrypoints
- Governance parameters match course specification (1d / 7d / 4% / 1% / 2d timelock)
- Oracle staleness bound (`maxStaleness = 3600s`)
- Documented UUPS storage gap preventing collision on upgrade

**Key residual risks**

- Centralized admin roles on testnet deployment until transferred to timelock
- Mock Chainlink feed on testnet (not production price discovery)
- Economic risks (oracle manipulation on mainnet) out of mock scope

---

## 2. Scope

### 2.1 Contracts reviewed

| Contract | Lines (approx.) | Purpose |
|----------|-----------------|--------|
| `ConstantProductAMM` | 155 | Swaps, liquidity |
| `LendingPool` | 126 | Borrow / liquidate |
| `YieldVault4626` | 80 | ERC-4626 vault |
| `DeFiGovToken` | 22 | Votes + permit |
| `DeFiGovernor` | 83 | Governance |
| `PriceOracle` | 35 | Staleness guard |
| `PoolFactory` | 90 | CREATE / CREATE2 |
| `ProtocolRegistryV1/V2` | 40 | UUPS registry |
| `Treasury` | 60 | Pull payments |
| `LPPositionNFT` | 24 | ERC-721 badge |
| Security case studies | 80 | Teaching PoCs |

### 2.2 Explicitly excluded

- OpenZeppelin library internals (`lib/openzeppelin-contracts*`)
- Frontend key management and RPC providers
- Subgraph off-chain indexer availability

---

## 3. Methodology

### 3.1 Automated analysis

| Tool | Command | Purpose |
|------|---------|--------|
| Slither | `slither src/ --filter-paths "lib\|test"` | Static analysis |
| Foundry test | `forge test` | Regression + PoCs |
| Foundry fuzz | `forge test --match-path test/fuzz` | Property checks |
| Foundry invariant | `forge test --match-path test/invariant` | Protocol invariants |
| Coverage | `forge coverage --report summary` | ≥90% `src/` lines |

### 3.2 Manual review

1. **Access control matrix** — every `onlyRole` / `onlyOwner` mapped to intended holder  
2. **CEI walkthrough** — each external mutator in AMM, lending, vault  
3. **Upgrade review** — storage layout diff V1→V2  
4. **Governance threat modeling** — flash loans, quorum, timelock bypass  
5. **Oracle threat modeling** — staleness, negative price, depeg (conceptual)

### 3.3 Test evidence

109 tests passing (see `docs/terminal-outputs/forge-test.txt`). Coverage **99.38%** line coverage on `src/` (`docs/COVERAGE.md`).

---

## 4. Findings

| ID | Severity | Title | Status |
|----|----------|-------|--------|
| S-01 | High | Reentrancy in teaching vault | **Fixed** |
| S-02 | High | Unguarded administrative `setFee` | **Fixed** |
| S-03 | Low | `block.timestamp` used for staleness only | Acknowledged |
| S-04 | Informational | Oracle assumes 8-decimal positive answer | Acknowledged |
| S-05 | Gas | Lazy yield accrual in vault | Wontfix |
| S-06 | Informational | Deployer retains admin on testnet | Acknowledged |

---

### S-01 — Reentrancy in sample vault (High) — FIXED

| Field | Detail |
|-------|--------|
| **Location** | `src/security/ReentrancyCaseStudy.sol` |
| **Description** | `VulnerableVault.withdraw` transfers ETH/tokens before zeroing balance, allowing `onWithdraw` hook to re-enter. |
| **Impact** | Attacker drains more than deposited balance (double spend). |
| **PoC** | `test_ReentrancyVulnerableDoubleSpend` in `test/unit/Security.t.sol` |
| **Recommendation** | Apply CEI: update balances before external call; or `nonReentrant`. |
| **Resolution** | `ReentrancyFixedVault` implements CEI; `test_ReentrancyFixedBlocks` proves fix. |

---

### S-02 — Missing access control on fee setter (High) — FIXED

| Field | Detail |
|-------|--------|
| **Location** | `src/security/AccessControlCaseStudy.sol` |
| **Description** | `VulnerableFeeModule.setFee` is `external` with no auth. |
| **Impact** | Any account sets protocol fee to 100%, griefing LPs/users. |
| **PoC** | `test_AccessControlAnyoneSetsFee` |
| **Recommendation** | `AccessControl` with `FEE_ADMIN_ROLE` or Ownable. |
| **Resolution** | `AccessControlFixed`; `test_AccessControlFixedReverts` |

---

### S-03 — Timestamp for oracle staleness (Low) — ACKNOWLEDGED

| Field | Detail |
|-------|--------|
| **Location** | `PriceOracle.latestPrice` |
| **Description** | Uses `block.timestamp - updatedAt` vs `maxStaleness`. |
| **Impact** | Miner manipulation bounded to ~15s; acceptable for staleness guard, not for randomness. |
| **Status** | Compliant with course rule (no randomness from timestamp). |

---

### S-04 — Oracle decimal assumptions (Informational) — ACKNOWLEDGED

| Field | Detail |
|-------|--------|
| **Location** | `PriceOracle`, `LendingPool` |
| **Description** | Price normalized with `1e8` divisor matching mock feed decimals. |
| **Impact** | Wrong decimals on mainnet feed would misprice loans. |
| **Mitigation** | Production deployment must use feed `decimals()` dynamically (future hardening). |

---

### S-05 — Lazy yield accrual (Gas) — WONTFIX

| Field | Detail |
|-------|--------|
| **Location** | `YieldVault4626` |
| **Description** | Yield accrues on user interaction, not per-block. |
| **Impact** | Slight accounting lag; gas savings on L2. |
| **Decision** | Accepted for MVP; documented in gas report. |

---

### S-06 — Testnet admin centralization (Informational) — ACKNOWLEDGED

| Field | Detail |
|-------|--------|
| **Location** | Deployment script / `AccessControl` roles |
| **Description** | Deployer holds `DEFAULT_ADMIN`, `PAUSER`, `RISK_ADMIN` until governance transfer. |
| **Impact** | Malicious deployer could pause or change LTV. |
| **Mitigation** | Production: grant roles to timelock only; run `VerifyDeployment.s.sol`. |

---

## 5. Centralization analysis

| Role | Holder (testnet) | Powers | If compromised |
|------|------------------|--------|----------------|
| `DEFAULT_ADMIN` | Deployer → Timelock | Grant/revoke roles, upgrade registry | Full protocol control |
| `PAUSER_ROLE` | Admin | Pause AMM/lending | Denial of service |
| `RISK_ADMIN_ROLE` | Admin / Timelock | `setLtv` | Under-collateralized loans if set to 100% |
| `MINTER_ROLE` (NFT) | Admin | Mint LP badges | Cosmetic spam only |
| Timelock | Governor only | Execute proposals after delay | Bounded by token vote |

**Treasury:** withdrawals use **pull** pattern (`scheduleWithdrawal` + `claimWithdrawal`); spender must hold `SPENDER_ROLE` (intended: timelock).

---

## 6. Governance attack analysis

| Attack | Description | Defense |
|--------|-------------|---------|
| Flash-loan vote | Borrow DSG, vote, repay same block | `ERC20Votes` checkpoints; votes from prior delegation |
| Whale takeover | Single holder > quorum | 4% quorum + 1% proposal threshold limits casual proposals |
| Proposal spam | Many proposals | Proposal threshold + gas cost |
| Timelock bypass | Direct call to guarded function | Critical calls only via timelock executor |
| Execution frontrun | MEV on `execute` | Public execution after delay; acceptable |

Lifecycle demonstrated in `Governance.t.sol::test_ProposeVoteQueueExecute`.

---

## 7. Oracle attack analysis

| Attack | Description | Defense |
|--------|-------------|---------|
| Stale price | Feed not updated | `StalePrice` revert after `maxStaleness` |
| Negative/zero price | Corrupt feed | `InvalidPrice` revert |
| Spot manipulation | DEX price vs Chainlink | Uses external feed, not AMM spot |
| Feed depeg | L2 sequencer issues | Operational monitoring (off-chain) |

Fork test `testFork_ChainlinkFeedLatest` (optional skip without RPC) validates real feed interface.

---

## 8. Checks-Effects-Interactions matrix

| Contract | Function | Pattern |
|----------|----------|---------|
| AMM | `swapExactTokensForTokens` | Update reserves → transfer out |
| AMM | `addLiquidity` / `removeLiquidity` | Mint/burn LP then transfers |
| Lending | `borrow` / `repay` | Update balances before token move |
| Lending | `liquidate` | Update debt/collateral before transfers |
| Vault | `deposit` / `withdraw` | OZ ERC4626 + `nonReentrant` |
| All above | — | `nonReentrant` modifier as belt-and-suspenders |

No `tx.origin` authorization. No `transfer`/`send` for ETH. ERC-20 via `SafeERC20`.

---

## 9. Slither appendix

**Command (run before submission):**

```bash
python -m slither src/ --filter-paths "lib|test" --json docs/slither-report.json
```

**Latest run (repository):** 45 informational/low findings, **0 High, 0 Medium** — see `docs/slither-report.json` and `docs/slither-report.txt`.

**CI:** `.github/workflows/ci.yml` uses `crytic/slither-action` on `src/`.

**Requirement:** Zero High, zero Medium at submission. Attach `slither-report.json` to defense materials.

**Expected low/informational themes:** naming conventions, complex functions in AMM `addLiquidity` branches — justify in defense if flagged.

---

## 10. Conclusion

The DeFi Super-App meets the course security bar after documented remediation of reentrancy and access-control teaching cases. Residual items are operational (testnet keys, Slither artifact, live deploy verification). No Critical or unfixed High issues remain in `src/` at this commit.

**Sign-off (team internal):** Ready for Base Sepolia deployment and instructor review pending Slither + L2 verify.

---

*End of audit report — print-friendly; ~8+ pages at 11pt with tables.*
