# Push + deploy (wallet 0xDc21AC231F5A49FC756D4fd32997c076cD7c6cFc)

Your Base Sepolia wallet is funded. Use the **private key of that address** (never commit it).

## 1. GitHub push

```powershell
cd "c:\Users\Aldoshh\Desktop\blockchain final\defi-super-app"
git remote set-url origin https://github.com/Aldik-droid/finalproject_blockchain_2.git
git push -u origin main
```

If prompted, sign in to GitHub or use a [Personal Access Token](https://github.com/settings/tokens) as password.

## 2. Base Sepolia deploy

```powershell
$env:PRIVATE_KEY = "0x<64-hex-chars-for-0xDc21AC...>"
$env:BASESCAN_API_KEY = "<optional>"
.\scripts\deploy-base-sepolia.ps1
```

This updates `deployments/base-sepolia.json` and `frontend/.env`.

## 3. Subgraph

After deploy, set AMM address in `subgraph/subgraph.yaml`, then:

```powershell
cd subgraph
npx graph auth --studio <DEPLOY_KEY>
npx graph deploy --studio defi-super-app
```

Update `VITE_SUBGRAPH_URL` in `frontend/.env`.
