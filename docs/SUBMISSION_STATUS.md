# Submission status (automated run)

## Completed automatically

| Step | Status |
|------|--------|
| 109 tests passing | Done |
| Coverage 99.38% on `src/` | Done |
| Slither run (0 High / 0 Medium in JSON) | Done — `docs/slither-report.json` |
| Subgraph `codegen` + `build` | Done — `subgraph/` |
| `frontend/.env` created (local Anvil addresses) | Done |
| English report `docs/BChT2_Final_Report_SE-2402.docx` | Done |
| Git initial commit | Done — `d2a9fb3` |
| Deploy script + `scripts/deploy-base-sepolia.ps1` | Done |

## Blocked (requires you)

| Step | Reason | Action |
|------|--------|--------|
| **Base Sepolia deploy** | Wallet `0xE2Bace…072E6` has **0 ETH** on Base Sepolia | Fund via [Base Sepolia faucet](https://www.coinbase.com/faucets/base-ethereum-sepolia-faucet), then run `.\scripts\deploy-base-sepolia.ps1` |
| **Contract verify** | Needs `BASESCAN_API_KEY` optional | Set env var, re-run deploy with `--verify` |
| **Subgraph publish** | No `GRAPH_DEPLOY_KEY` / Studio login | `cd subgraph && npx graph auth --studio <KEY> && npx graph deploy --studio defi-super-app` |
| **GitHub push** | — | https://github.com/Aldik-droid/finalproject_blockchain_2 |

## One-command deploy (after faucet)

```powershell
cd defi-super-app
$env:PRIVATE_KEY = "<your 0x... key>"
$env:BASESCAN_API_KEY = "<optional>"
.\scripts\deploy-base-sepolia.ps1
```
