const SUBGRAPH_URL =
  import.meta.env.VITE_SUBGRAPH_URL ??
  'https://api.studio.thegraph.com/query/placeholder/defi-super-app/version/latest';

export type IndexedSwap = {
  id: string;
  sender: string;
  amount0In: string;
  amount1In: string;
  amount0Out: string;
  amount1Out: string;
  timestamp: string;
};

export async function fetchRecentSwaps(): Promise<IndexedSwap[]> {
  const query = `{
    swaps(first: 10, orderBy: timestamp, orderDirection: desc) {
      id sender amount0In amount1In amount0Out amount1Out timestamp
    }
  }`;
  const res = await fetch(SUBGRAPH_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query }),
  });
  if (!res.ok) throw new Error('Subgraph unavailable');
  const json = await res.json();
  if (json.errors?.length) throw new Error(json.errors[0].message ?? 'GraphQL error');
  return json.data?.swaps ?? [];
}
