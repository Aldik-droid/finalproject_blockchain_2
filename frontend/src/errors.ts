export function friendlyError(err: unknown): string {
  if (!err) return 'Unknown error';
  const e = err as { code?: number; shortMessage?: string; message?: string; name?: string };
  if (e.code === 4001 || e.name === 'UserRejectedRequestError') {
    return 'Transaction rejected in wallet.';
  }
  if (e.message?.includes('insufficient funds')) {
    return 'Insufficient balance for gas or tokens.';
  }
  if (e.message?.includes('chain') || e.message?.includes('network')) {
    return 'Wrong network — switch to Base Sepolia.';
  }
  return e.shortMessage ?? e.message ?? 'Transaction failed.';
}
