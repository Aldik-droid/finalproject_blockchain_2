import { useEffect, useState } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { WagmiProvider, useAccount, useConnect, useDisconnect, useReadContract, useSwitchChain, useWriteContract } from 'wagmi';
import { baseSepolia } from 'wagmi/chains';
import { parseEther, formatEther } from 'viem';
import { config, chains } from './wagmi';
import { ammAbi, vaultAbi, govTokenAbi, governorAbi, erc20Abi, CONTRACTS, PROPOSAL_STATES } from './abis';
import { fetchRecentSwaps, type IndexedSwap } from './subgraph';
import { friendlyError } from './errors';
import './App.css';

const queryClient = new QueryClient();

function DeFiApp() {
  const { address, chain, isConnected } = useAccount();
  const { connect, connectors, isPending: connecting } = useConnect();
  const { disconnect } = useDisconnect();
  const { switchChain } = useSwitchChain();
  const { writeContractAsync } = useWriteContract();

  const [status, setStatus] = useState('');
  const [swapAmount, setSwapAmount] = useState('1');
  const [depositAmount, setDepositAmount] = useState('10');
  const [proposalId, setProposalId] = useState('0');
  const [swaps, setSwaps] = useState<IndexedSwap[]>([]);
  const [subgraphError, setSubgraphError] = useState('');

  const wrongChain = isConnected && chain?.id !== baseSepolia.id;

  const { data: reserves } = useReadContract({
    address: CONTRACTS.amm,
    abi: ammAbi,
    functionName: 'getReserves',
    query: { enabled: CONTRACTS.amm !== '0x0000000000000000000000000000000000000000' },
  });

  const { data: govBalance } = useReadContract({
    address: CONTRACTS.govToken,
    abi: govTokenAbi,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  });

  const { data: votes } = useReadContract({
    address: CONTRACTS.govToken,
    abi: govTokenAbi,
    functionName: 'getVotes',
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  });

  const { data: delegate } = useReadContract({
    address: CONTRACTS.govToken,
    abi: govTokenAbi,
    functionName: 'delegates',
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  });

  const { data: vaultShares } = useReadContract({
    address: CONTRACTS.vault,
    abi: vaultAbi,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
    query: { enabled: !!address },
  });

  const { data: proposalState } = useReadContract({
    address: CONTRACTS.governor,
    abi: governorAbi,
    functionName: 'state',
    args: [BigInt(proposalId || '0')],
    query: { enabled: CONTRACTS.governor !== '0x0000000000000000000000000000000000000000' },
  });

  useEffect(() => {
    fetchRecentSwaps()
      .then(setSwaps)
      .catch((e) => setSubgraphError(friendlyError(e)));
  }, []);

  async function runTx(label: string, fn: () => Promise<unknown>) {
    setStatus(`Submitting ${label}…`);
    try {
      await fn();
      setStatus(`${label} submitted.`);
    } catch (e) {
      setStatus(friendlyError(e));
    }
  }

  async function handleSwap() {
    if (!address) return;
    await runTx('swap', async () => {
      await writeContractAsync({
        address: CONTRACTS.token0,
        abi: erc20Abi,
        functionName: 'approve',
        args: [CONTRACTS.amm, parseEther(swapAmount)],
      });
      await writeContractAsync({
        address: CONTRACTS.amm,
        abi: ammAbi,
        functionName: 'swapExactTokensForTokens',
        args: [parseEther(swapAmount), 0n, true, address],
      });
    });
  }

  async function handleDeposit() {
    if (!address) return;
    await runTx('vault deposit', async () => {
      await writeContractAsync({
        address: CONTRACTS.token0,
        abi: erc20Abi,
        functionName: 'approve',
        args: [CONTRACTS.vault, parseEther(depositAmount)],
      });
      await writeContractAsync({
        address: CONTRACTS.vault,
        abi: vaultAbi,
        functionName: 'deposit',
        args: [parseEther(depositAmount), address],
      });
    });
  }

  async function handleVote() {
    await runTx('vote', () =>
      writeContractAsync({
        address: CONTRACTS.governor,
        abi: governorAbi,
        functionName: 'castVote',
        args: [BigInt(proposalId || '0'), 1],
      }),
    );
  }

  return (
    <div className="layout">
      <header>
        <h1>DeFi Super-App</h1>
        <p className="subtitle">BChT2 Final · Option A · SE-2402</p>
        <p className="team">Nursultan Tursunbaev · Zaki Sadaqatzada · Aldiyar Zharylkassyn</p>
      </header>

      <section className="card">
        <h2>Wallet</h2>
        {!isConnected ? (
          <button disabled={connecting} onClick={() => connect({ connector: connectors[0] })}>
            Connect MetaMask
          </button>
        ) : (
          <>
            <p>
              <strong>Address:</strong> {address}
            </p>
            <button onClick={() => disconnect()}>Disconnect</button>
          </>
        )}
        {wrongChain && (
          <div className="banner">
            Wrong network. Please switch to Base Sepolia.
            <button onClick={() => switchChain({ chainId: baseSepolia.id })}>Switch network</button>
          </div>
        )}
      </section>

      <section className="card">
        <h2>Protocol state</h2>
        <ul>
          <li>AMM reserves: {reserves ? `${formatEther(reserves[0])} / ${formatEther(reserves[1])}` : '—'}</li>
          <li>DSG balance: {govBalance !== undefined ? formatEther(govBalance) : '—'}</li>
          <li>Voting power: {votes !== undefined ? formatEther(votes) : '—'}</li>
          <li>Delegate: {delegate ?? '—'}</li>
          <li>Vault shares: {vaultShares !== undefined ? formatEther(vaultShares) : '—'}</li>
        </ul>
      </section>

      <section className="card">
        <h2>Actions</h2>
        <div className="row">
          <label>
            Swap amount (token0)
            <input value={swapAmount} onChange={(e) => setSwapAmount(e.target.value)} />
          </label>
          <button disabled={!isConnected || wrongChain} onClick={handleSwap}>
            Swap
          </button>
        </div>
        <div className="row">
          <label>
            Vault deposit
            <input value={depositAmount} onChange={(e) => setDepositAmount(e.target.value)} />
          </label>
          <button disabled={!isConnected || wrongChain} onClick={handleDeposit}>
            Deposit
          </button>
        </div>
        <div className="row">
          <label>
            Proposal ID
            <input value={proposalId} onChange={(e) => setProposalId(e.target.value)} />
          </label>
          <button disabled={!isConnected || wrongChain} onClick={handleVote}>
            Vote For
          </button>
        </div>
        <p>Proposal state: {proposalState !== undefined ? PROPOSAL_STATES[Number(proposalState)] ?? proposalState : '—'}</p>
        {status && <p className="status">{status}</p>}
      </section>

      <section className="card">
        <h2>Indexed swaps (The Graph)</h2>
        {subgraphError && <p className="status">{subgraphError}</p>}
        {swaps.length === 0 && !subgraphError && <p>No indexed swaps yet — deploy subgraph after testnet deployment.</p>}
        <ul>
          {swaps.map((s) => (
            <li key={s.id}>
              {s.sender.slice(0, 8)}… — in: {s.amount0In} / out: {s.amount1Out} @ {s.timestamp}
            </li>
          ))}
        </ul>
      </section>

      <footer>
        <p>Target chain: Base Sepolia ({chains[0].id})</p>
      </footer>
    </div>
  );
}

export default function App() {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <DeFiApp />
      </QueryClientProvider>
    </WagmiProvider>
  );
}
