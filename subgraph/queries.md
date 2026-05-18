# GraphQL Queries (minimum 5 documented)

## 1. Recent swaps
```graphql
{ swaps(first: 10, orderBy: timestamp, orderDirection: desc) { id sender amount0In amount1Out timestamp } }
```

## 2. Protocol totals
```graphql
{ protocol(id: "1") { totalSwaps totalLiquidityEvents } }
```

## 3. Daily volume
```graphql
{ poolDayDatas(first: 7, orderBy: date, orderDirection: desc) { date swapCount volumeToken0 } }
```

## 4. Liquidity events by user
```graphql
{ liquidityMints(where: { sender: "0x..." }) { amount0 amount1 liquidity timestamp } }
```

## 5. Swaps in block range
```graphql
{ swaps(where: { blockNumber_gte: "1000", blockNumber_lte: "2000" }) { id blockNumber } }
```
