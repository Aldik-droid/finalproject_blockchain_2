# DeFi Super-App — BChT2 Final Project (Option A)

**Course:** Blockchain Technologies 2  
**Group:** SE-2402  
**Team:** Nursultan Tursunbaev, Zaki Sadaqatzada, Aldiyar Zharylkassyn

Production-style educational capstone: **AMM + lending + ERC-4626 vault**, **Chainlink** prices, **OpenZeppelin Governor + Timelock DAO**, **The Graph** indexing, **Base Sepolia** L2 target.

## Team ownership

| Member | Area |
|--------|------|
| Nursultan Tursunbaev | AMM, factory, deployment, gas report |
| Zaki Sadaqatzada | Lending, oracle, security audit |
| Aldiyar Zharylkassyn | Vault, governance, frontend, subgraph |

## Quick start

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation) 1.7+
- Node.js 20+
- MetaMask

### Contracts
```bash
forge install
forge test
forge coverage
```

### Frontend
```bash
cd frontend
cp .env.example .env
npm install
npm run dev
```

### Deploy (Base Sepolia)
```powershell
# PowerShell — use your funded testnet key (never commit it)
$env:BASE_SEPOLIA_RPC = "https://sepolia.base.org"
forge script script/Deploy.s.sol `
  --rpc-url $env:BASE_SEPOLIA_RPC `
  --broadcast --verify `
  --private-key <YOUR_PRIVATE_KEY>
```

The script writes `deployments/base-sepolia.json` automatically. Copy addresses into `frontend/.env`.

Post-deploy verification:
```powershell
$env:TIMELOCK = "0x..."; $env:GOVERNOR = "0x..."; $env:TREASURY = "0x..."
forge script script/VerifyDeployment.s.sol --rpc-url $env:BASE_SEPOLIA_RPC
```

Local smoke test output: `deployments/anvil-local.json`, `docs/terminal-outputs/forge-deploy-local-anvil.txt`.

## Architecture

- `ConstantProductAMM` — x·y=k, 0.3% fee, LP ERC-20 per pool
- `LendingPool` — collateral, borrow, health factor, liquidation
- `YieldVault4626` — ERC-4626 yield vault
- `DeFiGovToken` — ERC20Votes + Permit
- `DeFiGovernor` + `TimelockController` — 1d delay, 7d vote, 4% quorum, 2d timelock
- `PriceOracle` + Chainlink feed — staleness guard
- `PoolFactory` — CREATE + CREATE2 pools
- `ProtocolRegistryV1/V2` — UUPS upgradeable registry
- `LPPositionNFT` — ERC-721 badges

See `docs/BChT2_Final_Report_SE-2402.docx` (main English report), `docs/ARCHITECTURE.md`, `docs/AUDIT_REPORT.md`, `docs/GAS_REPORT.md`, `docs/COVERAGE.md`, `docs/COMPLIANCE_CHECKLIST.md`.

## Tests

109 tests (unit, fuzz, invariant, fork). All passing locally:
```bash
forge test
```

## Subgraph

```bash
cd subgraph
# graph codegen && graph deploy after setting ammAddress
```

Documented queries: `subgraph/queries.md`.

## L2 deployment

Target: **Base Sepolia** (chain id 84532).  
After deploy, verify on [BaseScan Sepolia](https://sepolia.basescan.org/) and update `deployments/base-sepolia.json`.

## License

MIT — educational use.
