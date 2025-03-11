import { http, createPublicClient, getContract, formatEther } from 'viem';
import { mainnet } from 'viem/chains';
import { Command } from 'commander';
import { IUsdnLongFarmingAbi } from '../dist/abi';
import { IUsdnProtocolAbi } from '../../usdn-contracts/dist/abi';

const program = new Command();

program.description('Find slashable positions').option('-r, --rpc-url <URL>', 'RPC URL (https)').parse(process.argv);

const options = program.opts();

async function main() {
  if (!options.rpcUrl) {
    console.error('Please specify the RPC URL');
    process.exit(1);
  }

  const client = createPublicClient({
    chain: mainnet,
    transport: http(options.rpcUrl),
  });

  const farming = {
    address: '0xf9d36078a248af249aa57ae1d5d0c1033d6bbe27',
    abi: IUsdnLongFarmingAbi,
  } as const;

  const protocol = getContract({
    address: '0x656cb8c6d154aad29d8771384089be5b5141f01a',
    abi: IUsdnProtocolAbi,
    client,
  });

  const highestTick = await protocol.read.getHighestPopulatedTick();
  console.log('highest tick', highestTick);
  let currentTick = highestTick + 100;
  while (currentTick <= Math.max(highestTick + 2000, 82000)) {
    let tickVersion = await protocol.read.getTickVersion([currentTick]);
    if (tickVersion === 0n) {
      currentTick += 100;
      continue;
    }
    tickVersion -= 1n;

    const calls = [...Array(50).keys()].map((i) => {
      return {
        functionName: 'harvest',
        args: [currentTick, tickVersion, BigInt(i)],
        ...farming,
      } as const;
    });
    const results = await client.multicall({
      contracts: calls,
      allowFailure: true,
    });
    const pos = results
      .map((res, i) => [res, i] as const)
      .filter(([res, _]) => {
        if (res.status === 'failure' || !res.result[0]) {
          return false;
        }
        return true;
      })
      .map(([_, i]) => {
        return i;
      });
    const farmingContract = getContract({ client, ...farming });
    for (const i of pos) {
      const pendingRewards = await farmingContract.read.pendingRewards([currentTick, tickVersion, BigInt(i)]);
      console.log('position should be slashed', [currentTick, tickVersion, i], formatEther(pendingRewards / 10n));
    }
    currentTick += 100;
  }

  console.log('finished');
}

main();
