import { Swap as SwapEvent, Mint as MintEvent } from "../generated/ConstantProductAMM/AMM";
import { Protocol, Swap, LiquidityMint, PoolDayData } from "../generated/schema";
import { BigInt } from "@graphprotocol/graph-ts";

const PROTOCOL_ID = "1";

function dayId(timestamp: BigInt): string {
  let day = timestamp.toI32() / 86400;
  return day.toString();
}

function getOrCreateProtocol(): Protocol {
  let p = Protocol.load(PROTOCOL_ID);
  if (p == null) {
    p = new Protocol(PROTOCOL_ID);
    p.totalSwaps = BigInt.zero();
    p.totalLiquidityEvents = BigInt.zero();
  }
  return p;
}

export function handleSwap(event: SwapEvent): void {
  let id = event.transaction.hash.toHexString() + "-" + event.logIndex.toString();
  let swap = new Swap(id);
  swap.sender = event.params.sender;
  swap.amount0In = event.params.amount0In;
  swap.amount1In = event.params.amount1In;
  swap.amount0Out = event.params.amount0Out;
  swap.amount1Out = event.params.amount1Out;
  swap.timestamp = event.block.timestamp;
  swap.blockNumber = event.block.number;
  swap.save();

  let protocol = getOrCreateProtocol();
  protocol.totalSwaps = protocol.totalSwaps.plus(BigInt.fromI32(1));
  protocol.save();

  let did = dayId(event.block.timestamp);
  let day = PoolDayData.load(did);
  if (day == null) {
    day = new PoolDayData(did);
    day.date = event.block.timestamp.toI32() / 86400;
    day.swapCount = 0;
    day.volumeToken0 = BigInt.zero();
  }
  day.swapCount = day.swapCount + 1;
  day.volumeToken0 = day.volumeToken0.plus(event.params.amount0In);
  day.save();
}

export function handleMint(event: MintEvent): void {
  let id = event.transaction.hash.toHexString() + "-mint-" + event.logIndex.toString();
  let mint = new LiquidityMint(id);
  mint.sender = event.params.sender;
  mint.amount0 = event.params.amount0;
  mint.amount1 = event.params.amount1;
  mint.liquidity = event.params.liquidity;
  mint.timestamp = event.block.timestamp;
  mint.save();

  let protocol = getOrCreateProtocol();
  protocol.totalLiquidityEvents = protocol.totalLiquidityEvents.plus(BigInt.fromI32(1));
  protocol.save();
}
