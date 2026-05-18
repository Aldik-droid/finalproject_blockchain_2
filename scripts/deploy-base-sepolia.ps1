# Deploy DeFi Super-App to Base Sepolia and wire frontend + subgraph.
# Prerequisites: Foundry on PATH, funded wallet on Base Sepolia (https://www.coinbase.com/faucets/base-ethereum-sepolia-faucet)
$ErrorActionPreference = "Stop"
$env:Path = "$env:USERPROFILE\.foundry\bin;" + $env:Path
Set-Location (Split-Path $PSScriptRoot -Parent)

if (-not $env:PRIVATE_KEY) {
    Write-Error "Set PRIVATE_KEY to your testnet wallet (0x + 64 hex chars)."
}
$m = [regex]::Match($env:PRIVATE_KEY.Trim(), '0x[a-fA-F0-9]{64}')
if (-not $m.Success) { Write-Error "PRIVATE_KEY must contain a valid 32-byte hex key." }
$pk = $m.Value
$addr = cast wallet address --private-key $pk
$bal = cast balance $addr --rpc-url https://sepolia.base.org
Write-Host "Deployer: $addr"
Write-Host "Balance:  $bal wei"
if ($bal -eq "0") {
    Write-Error "Wallet has 0 ETH on Base Sepolia. Fund it via the Base Sepolia faucet first."
}

$verify = @()
if ($env:BASESCAN_API_KEY -or $env:ETHERSCAN_API_KEY) { $verify += "--verify" }

forge script script/Deploy.s.sol `
    --rpc-url https://sepolia.base.org `
    --broadcast @verify `
    --private-key $pk

$json = Get-Content "deployments\base-sepolia.json" | ConvertFrom-Json
$c = $json.contracts
@"
VITE_AMM_ADDRESS=$($c.ConstantProductAMM)
VITE_VAULT_ADDRESS=$($c.YieldVault4626)
VITE_GOV_TOKEN_ADDRESS=$($c.DeFiGovToken)
VITE_GOVERNOR_ADDRESS=$($c.DeFiGovernor)
VITE_TOKEN0_ADDRESS=$($c.ProtocolToken)
VITE_SUBGRAPH_URL=https://api.studio.thegraph.com/query/placeholder/defi-super-app/version/latest
"@ | Set-Content "frontend\.env" -Encoding utf8

$env:TIMELOCK = $c.TimelockController
$env:GOVERNOR = $c.DeFiGovernor
$env:TREASURY = $c.Treasury
forge script script/VerifyDeployment.s.sol --rpc-url https://sepolia.base.org

Write-Host "Done. Update subgraph/subgraph.yaml address and run: cd subgraph; graph deploy"
