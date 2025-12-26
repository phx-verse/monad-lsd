import { network } from "hardhat";
import logger from "./logger.js";
import util from "../scripts/util.js";

const EPOCH_BLOCKS = util.EPOCH_BLOCKS;

const { ethers } = await network.connect();
const MonLsd = await ethers.getContractAt("MonLsdUpgradeable", process.env.MON_LSD_ADDRESS!);

const handledEpochs: Map<bigint, boolean> = new Map();

async function startMonadLsdService() {
    logger.info('Starting MonadLsd service...');
    setInterval(async () => {
        try {
            logger.info('MonadLsd task one round: ');
            // invoke claimReward
            let totalReward = await MonLsd.totalUnclaimedReward.staticCall();
            if (totalReward > 0) {
                logger.info(`Claiming rewards: ${ethers.formatEther(totalReward)} ETH`);
                const tx = await MonLsd.claimReward();
                await tx.wait();
            }

            let currentEpoch = await MonLsd.currentEpoch.staticCall();
            let currentBlock = await ethers.provider.getBlockNumber();
            
            // invoke stakePending
            if (isInOperateWindow(currentBlock, currentEpoch)) {
                let pendingStake = await MonLsd.pendingStake();
                let pendingRewards = await MonLsd.pendingRewards();
                let isEpochHandled = handledEpochs.get(currentEpoch) || false;
                if ((pendingRewards > 0 || pendingStake > 0) && !isEpochHandled) {
                    logger.info(`Staking pending: ${ethers.formatEther(pendingStake)} ETH, pending rewards: ${ethers.formatEther(pendingRewards)} ETH`);
                    const tx = await MonLsd.stakePending();
                    let receipt = await tx.wait();
                    
                    if (receipt && receipt.status === 0) {
                        handledEpochs.set(currentEpoch, true);
                    }
                }

                // invoke handlePendingUndelegate
                let pendingUnstake = await MonLsd.pendingUnstake();
                if (pendingUnstake > 0) {
                    logger.info(`Handling pending undelegate: ${ethers.formatEther(pendingUnstake)} ETH`);
                    const tx = await MonLsd.handlePendingUndelegate();
                    await tx.wait();
                }
            }

            // invoke handleWithdraws
            let withdrawQueueLen = await MonLsd.withdrawQueueLen();
            if (withdrawQueueLen > 0) {
                let firstReady = await MonLsd.isFirstWithdrawItemReady.staticCall();
                if (!firstReady) return;
                logger.info(`Handling withdraws, queue length: ${withdrawQueueLen}`);
                const tx = await MonLsd.handleWithdraws();
                await tx.wait();
            }

        } catch (err) {
            logger.error('Error in MonadLsd service loop:', err);
        }
        
    }, 1000 * 60 * 13); // every 13 minutes
}

startMonadLsdService().catch(err => {
    console.error(err);
    process.exit(1);
});

function boundaryBlock(epoch: bigint) {
    return epoch * BigInt(EPOCH_BLOCKS);
}

// Check if we are within the operate window (last 5000 blocks of the epoch)
function isInOperateWindow(currentBlock: number, epoch: bigint) {
    return boundaryBlock(epoch) - BigInt(currentBlock) <= BigInt(4000);
}