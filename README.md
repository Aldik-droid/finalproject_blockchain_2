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

## L2 deployment (Base Sepolia — live)

| Contract | Address |
|----------|---------|
| ConstantProductAMM | [0x006C…2e08](https://sepolia.basescan.org/address/0x006C8F6139789A10eA3d74Fe4BE5901280d12e08) |
| LendingPool | [0xaB5e…69C7](https://sepolia.basescan.org/address/0xaB5e117bA698d720f92A95BD06B51394DDEb69C7) |
| YieldVault4626 | [0x1e47…4bCE](https://sepolia.basescan.org/address/0x1e47d477868557e8a3138d4a945326912EC04bCE) |
| DeFiGovToken | [0xCfC6…CDf3](https://sepolia.basescan.org/address/0xCfC6EDbd5d57023610276920700fAe9332BFCDf3) |
| DeFiGovernor | [0xBDEa…273d](https://sepolia.basescan.org/address/0xBDEa97Fb1044A22A32509da6E4A6dC4C610D273d) |
| TimelockController | [0x7757…82A6](https://sepolia.basescan.org/address/0x775745c005282a19f0872767e7c873aB8dA882A6) |

Full list: `deployments/base-sepolia.json`. Post-deploy check: `docs/terminal-outputs/verify-deployment.txt`.

## Repository

https://github.com/Aldik-droid/finalproject_blockchain_2

## License

MIT — educational use.
