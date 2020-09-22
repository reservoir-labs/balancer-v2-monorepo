import { deploy } from './helpers/deploy';
import { ethers } from '@nomiclabs/buidler';
import { setupPool } from './helpers/pools';
import { deployTokens, mintTokens, TokenList } from '../test/helpers/tokens';
import { toFixedPoint } from './helpers/fixedPoint';
import { Contract, Signer } from 'ethers';
import { getDiffsSwapsAndAmounts } from './helpers/trading';

let vault: Contract;
let engine: Contract;
let tokens: TokenList;

let controller: Signer;
let trader: Signer;

const BATCHED_SWAP_TOTAL_POOLS = 8;

async function main() {
  [, controller, trader] = await ethers.getSigners();

  vault = await deploy('Vault');
  engine = await deploy('TradingEngine', vault.address);

  tokens = await deployTokens(['DAI', 'MKR', 'BAT']);

  for (const symbol in tokens) {
    // controller tokens are used to initialize pools
    await mintTokens(tokens, symbol, controller, 100e18);
    // trader tokens are used to trade and not have non-zero balances
    await mintTokens(tokens, symbol, trader, 100e18);

    await tokens[symbol].connect(trader).approve(engine.address, (100e18).toString());
  }

  await batchedSwap();
}

async function batchedSwap() {
  console.log('# Batched swap: multiple batched pools for the same pair');

  // 50-50 DAI-MKR pools

  const pools: Array<string> = [];
  for (let i = 0; i < BATCHED_SWAP_TOTAL_POOLS; ++i) {
    pools.push(
      await setupPool(vault, tokens, controller, [
        ['DAI', 50],
        ['MKR', 50],
      ])
    );
  }

  // Trade DAI for MKR, putting 500 DAI into each pool

  for (let poolAmount = 1; poolAmount <= BATCHED_SWAP_TOTAL_POOLS; ++poolAmount) {
    const [diffs, swaps, amounts] = getDiffsSwapsAndAmounts(
      tokens,
      pools.slice(0, poolAmount).map((poolId) => {
        return { poolId, tokenIn: 'DAI', tokenOut: 'MKR', amount: 500 };
      })
    );

    const receipt = await (
      await engine
        .connect(trader)
        .swapExactAmountIn(
          tokens.DAI.address,
          tokens.MKR.address,
          500 * poolAmount,
          toFixedPoint(1),
          diffs,
          swaps,
          amounts
        )
    ).wait();

    console.log(
      `Using ${poolAmount} pools: ${printGas(receipt.gasUsed)} (${printGas(receipt.gasUsed / poolAmount)} per pool)`
    );
  }
}

function printGas(gas: number): string {
  return `${Math.trunc(gas / 1000)}k`;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });