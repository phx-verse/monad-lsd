const EPOCH_BLOCKS = 50000;

const BLOCK_TIME_MS = 400; // average block time in milliseconds

// estimate the withdraw finish time for a given amount of monLSD
function estimateWithdrawFinishBlock(currentBlock: bigint, targetEpoch: bigint): bigint {
    const blocksToWait = targetEpoch * BigInt(EPOCH_BLOCKS) - currentBlock;
    return blocksToWait;
}

function estimateWithdrawFinishBlockFromNow(currentBlock: bigint): bigint {
    const currentEpoch = currentBlock / BigInt(EPOCH_BLOCKS);
    const targetEpoch = currentEpoch + BigInt(2); // assuming 2 epochs to withdraw
    return estimateWithdrawFinishBlock(currentBlock, targetEpoch);
}

function estimateWithdrawFinishTimeFromNow(currentBlock: bigint): number {
    const blocksToWait = estimateWithdrawFinishBlockFromNow(currentBlock);
    return Number(blocksToWait) * BLOCK_TIME_MS;
}   

function estimateWithdrawFinishTime(currentBlock: bigint, targetEpoch: bigint): number {
    const blocksToWait = estimateWithdrawFinishBlock(currentBlock, targetEpoch);
    return Number(blocksToWait) * BLOCK_TIME_MS;
}

export default {
    estimateWithdrawFinishBlock,
    estimateWithdrawFinishBlockFromNow,
    estimateWithdrawFinishTimeFromNow,
    estimateWithdrawFinishTime,
    EPOCH_BLOCKS,
    BLOCK_TIME_MS,
};