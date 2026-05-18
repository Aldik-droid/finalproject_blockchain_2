# Architecture & Design Document — DeFi Super-App

**Team:** Nursultan Tursunbaev, Zaki Sadaqatzada, Aldiyar Zharylkassyn  
**Group:** SE-2402 · **Scenario:** Option A (DeFi Super-App)  
**Target network:** Base Sepolia (chainId 84532)

---

## 1. Introduction

This document describes the architecture of our capstone protocol: an integrated **AMM**, **lending market**, **ERC-4626 vault**, **oracle adapter**, and **DAO** deployed on an Ethereum L2. The design prioritizes auditability, OpenZeppelin reuse, and clear separation of concerns for team ownership.

---

## 2. System context (C4 Level 1)

```
                         ┌──────────────────────────────────────┐
                         │           External actors            │
                         │  Traders · Borrowers · LPs · Voters  │
                         └───────────────────┬──────────────────┘
                                             │
              ┌──────────────────────────────┼──────────────────────────────┐
              │                              │                              │
              ▼                              ▼                              ▼
     ┌────────────────┐           ┌─────────────────┐           ┌─────────────────┐
     │  React dApp      │  RPC      │  Smart contracts │  events  │  The Graph      │
     │  (Wagmi/Viem)    │──────────▶│  Base Sepolia    │─────────▶│  Subgraph       │
     └────────────────┘           └────────┬────────┘           └─────────────────┘
              │                              │
              │                              ├── Chainlink (or mock aggregator)
              │                              └── Timelock / Governor
              ▼
     MetaMask / WalletConnect (optional)
```

**Trust boundaries:** Users trust wallet software, RPC providers, and (on testnet) team-deployed contracts. They do not trust other users for custody—non-custodial design.

---

## 3. Container diagram (contracts)

```
                    ┌─────────────────┐
                    │ DeFiGovernor    │
                    └────────┬────────┘
                             │ proposes / executes
                    ┌────────▼────────┐
                    │ TimelockController│
                    └────────┬────────┘
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
  ┌─────────────┐    ┌─────────────┐    ┌──────────────┐
  │ LendingPool │    │ Treasury    │    │ Registry UUPS │
  └──────┬──────┘    └─────────────┘    └──────────────┘
         │ uses
  ┌──────▼──────┐         ┌──────────────────┐
  │ PriceOracle │◀────────│ MockChainlink    │
  └─────────────┘         └──────────────────┘

  ┌─────────────────┐     ┌─────────────────┐
  │ ConstantProduct │     │ YieldVault4626  │
  │ AMM + LPToken   │     │ (ERC-4626)      │
  └─────────────────┘     └─────────────────┘

  ┌─────────────────┐     ┌─────────────────┐
  │ PoolFactory     │     │ DeFiGovToken    │
  │ CREATE/CREATE2  │     │ ERC20Votes      │
  └─────────────────┘     └─────────────────┘
```

| Container | Responsibility |
|-----------|----------------|
| `ConstantProductAMM` | Trading, LP shares (`LPToken`) |
| `LendingPool` | Collateralized debt positions |
| `YieldVault4626` | Single-asset yield vault |
| `DeFiGovToken` | Governance voting (DSG) |
| `DeFiGovernor` + `TimelockController` | Parameter updates with delay |
| `PriceOracle` | Staleness-checked price reads |
| `PoolFactory` | Deploy additional AMM pairs |
| `ProtocolRegistry` | On-chain address book (upgradeable) |
| `Treasury` | Protocol fee custody (pull withdrawals) |

---

## 4. Sequence diagrams

### 4.1 Swap (AMM)

```
User          Frontend       AMM              token0/1
  │               │           │                  │
  │── approve ────┼───────────┼─────────────────▶│
  │── swap ───────┼──────────▶│                  │
  │               │           │── transferFrom ─▶│
  │               │           │◀─ compute out ───│
  │               │           │── transfer out ─▶│
  │               │           │── emit Swap ─────┼──▶ Subgraph
  │◀── receipt ───┼───────────│                  │
```

Steps: (1) approve input token; (2) `swapExactTokensForTokens` with `amountOutMin`; (3) reserves updated before outbound transfer (CEI); (4) indexer stores swap entity.

### 4.2 Governance (propose → execute)

```
Proposer     Governor      Timelock      LendingPool
   │            │              │               │
   │─ delegate ─▶             │               │
   │─ propose ──▶             │               │
   │  [1 day delay]           │               │
   │─ castVote ─▶             │               │
   │  [7 day period]          │               │
   │─ queue ─────▶            │               │
   │            │─ schedule ──▶               │
   │  [2 day delay]           │               │
   │─ execute ───▶            │── setLtv ────▶│
```

Matches OpenZeppelin GovernorTimelockControl pattern. Example calldata: `setLtv(7400)`.

### 4.3 Deposit collateral → borrow → liquidate

```
User         LendingPool    Oracle        Liquidator
  │               │            │               │
  │─ deposit ────▶│            │               │
  │─ borrow ─────▶│── price ──▶│               │
  │               │◀─ HF ok ───│               │
  │  [price drop] │            │               │
  │               │◀───────────│               │
  │               │◀─ liquidate ───────────────│
  │               │── seize collateral ────────▶│
```

Health factor = `(collateralValue × liquidationThreshold) / debt`. Liquidation when HF &lt; 1e18.

---

## 5. Data model & storage

### 5.1 AMM (non-upgradeable)

| Slot | Variable | Type |
|------|----------|------|
| immutable | `token0`, `token1`, `lpToken` | addresses |
| 0 | `reserve0` | uint256 |
| 1 | `reserve1` | uint256 |

### 5.2 LendingPool

| Variable | Type | Notes |
|----------|------|-------|
| `collateralBalance[user]` | mapping | Internal accounting |
| `borrowBalance[user]` | mapping | Debt |
| `ltvBps` | uint256 | Governance-tunable |

### 5.3 ProtocolRegistry V1 → V2 (UUPS)

**V1 slots (fixed order):**

1. `amm`  
2. `lendingPool`  
3. `vault`  
4. `treasury`  
5. `__gap[46]`  

**V2 append-only:**

6. `priceOracle`  
7. `registryVersion`  

**Proof of no collision:** V2 only appends; never reorders V1 variables. Upgrade tested in `TreasuryUpgrade.t.sol::test_UpgradeToV2`.

### 5.4 Subgraph entities

| Entity | Key fields |
|--------|------------|
| `Protocol` | `totalSwaps`, `totalLiquidityEvents` |
| `Swap` | amounts, sender, timestamp, block |
| `LiquidityMint` | amounts, liquidity minted |
| `PoolDayData` | daily aggregates |

---

## 6. Trust assumptions

| Actor | Trust level | Notes |
|-------|-------------|-------|
| Token holders | Economic | DSG controls governance |
| Deployer (testnet) | High | Must migrate admin to timelock |
| Chainlink feed | Medium | Honest updater; staleness bounded |
| The Graph | Low | Read-only indexer; UI fallback to RPC |
| L2 sequencer | Medium | Base liveness / ordering |

**Timelock powers:** execute governance payloads after 2-day delay; cannot arbitrarily upgrade AMM implementation (non-proxy) unless governed.

**Admin backdoor check:** `VerifyDeployment.s.sol` asserts timelock delay, governor params, treasury admin.

---

## 7. Design patterns (≥5 required)

| # | Pattern | Where | Justification |
|---|---------|-------|---------------|
| 1 | Factory | `PoolFactory` | Deploy many pools with deterministic CREATE2 addresses |
| 2 | UUPS proxy | `ProtocolRegistry` | Upgrade address book without redeploying core pools |
| 3 | CEI | AMM, lending, vault | Prevent reentrancy; clear state before external calls |
| 4 | Pull payments | `Treasury` | Users claim scheduled withdrawals—safer than push |
| 5 | AccessControl | All admin functions | Explicit roles vs single owner EOA |
| 6 | Pausable | AMM, lending | Emergency stop without upgrade |
| 7 | Oracle adapter | `PriceOracle` | Abstract Chainlink behind staleness API |
| 8 | Timelock | Governance | Delay malicious proposals |
| 9 | ReentrancyGuard | Value contracts | Defense in depth |

---

## 8. Architecture Decision Records (ADRs)

### ADR-1: OpenZeppelin Governor vs custom

- **Context:** Need spec-compliant DAO with minimal audit surface.  
- **Decision:** Use `Governor` + `TimelockController` + `ERC20Votes`.  
- **Consequences:** Long proposal cycles in tests; battle-tested code.

### ADR-2: Mock oracle on testnet

- **Context:** CI and Base Sepolia may lack canonical ETH/USD feed address.  
- **Decision:** Deploy `MockChainlinkAggregator`; fork tests hit mainnet feed.  
- **Consequences:** UI must not claim mainnet oracle security on testnet.

### ADR-3: Single primary AMM instance

- **Context:** Grading requires factory demo but UI needs one stable pool.  
- **Decision:** Deploy primary `ConstantProductAMM` in script; factory for extra pairs.  
- **Consequences:** Subgraph indexes primary AMM address from `subgraph.yaml`.

### ADR-4: Lazy vault yield

- **Context:** L2 gas sensitivity.  
- **Decision:** Accrue yield on deposit/withdraw/mint/redeem.  
- **Consequences:** Small inter-user fairness gap; documented in audit S-05.

### ADR-5: Base Sepolia as L2 target

- **Context:** Course allows Arbitrum/Optimism/Base/zkSync Sepolia.  
- **Decision:** Base Sepolia for low fees and BaseScan verification.  
- **Consequences:** Gas table compares ETH L1 $ vs L2 $ in `GAS_REPORT.md`.

---

## 9. Frontend architecture

- **Config:** `frontend/.env` — contract addresses + `VITE_SUBGRAPH_URL`  
- **Wagmi:** `baseSepolia` chain; auto switch prompt  
- **Data:** Mix of `useReadContract` (live state) and GraphQL (historical swaps)  
- **Errors:** `friendlyError()` maps revert codes and wallet rejections

---

## 10. Deployment topology

```
Developer machine
      │
      │ forge script Deploy.s.sol --broadcast --verify
      ▼
Base Sepolia
      │
      ├── deployments/base-sepolia.json  (generated)
      └── BaseScan verified source
```

Post-deploy: `VerifyDeployment.s.sol` with env addresses.

---

## 11. Future work (out of scope)

- Multi-feed oracle with `decimals()` auto-detect  
- Permissionless pool creation in UI  
- Formal verification of AMM invariant  
- Mainnet deployment with multisig admin

---

*End of architecture document — ~6+ pages printed with diagrams.*
