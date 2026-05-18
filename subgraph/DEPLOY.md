# Subgraph deployment (Base Sepolia)

1. Deploy contracts and copy `ConstantProductAMM` address from `deployments/base-sepolia.json`.
2. Edit `subgraph.yaml` — set `source.address` under `ammAddress` (or replace `{{ammAddress}}` in your manifest).
3. `npm install -g @graphprotocol/graph-cli` (if needed).
4. From `subgraph/`:

```bash
graph codegen
graph build
graph auth --studio <DEPLOY_KEY>
graph deploy --studio defi-super-app
```

5. Set `VITE_SUBGRAPH_URL` in `frontend/.env` to the Studio query URL.

Documented queries: `queries.md` (5 required by course spec).
