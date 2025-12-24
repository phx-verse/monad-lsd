import { network } from "hardhat";

const { ethers } = await network.connect();

const MonLsd = await ethers.getContractAt("MonLsdUpgradeable", process.env.MON_LSD_ADDRESS!);

async function startMonadLsdService() {
    setInterval(async () => {
        console.log('MonadLsd task one round: ');
        // invoke claimReward
        let totalReward = await MonLsd.totalUnclaimedReward.staticCall();
        if (totalReward > 0) {
            console.log(`Claiming rewards: ${ethers.formatEther(totalReward)} ETH`);
            const tx = await MonLsd.claimReward();
            await tx.wait();
        }

        let currentEpoch = await MonLsd.currentEpoch.staticCall();
        let currentBlock = await ethers.provider.getBlockNumber();
        
        // invoke stakePending
        if (isInOperateWindow(currentBlock, currentEpoch)) {
            let pendingStake = await MonLsd.pendingStake();
            let pendingRewards = await MonLsd.pendingRewards();
            if (pendingRewards > 0 || pendingStake > 0) {
                console.log(`Staking pending: ${ethers.formatEther(pendingStake)} ETH, pending rewards: ${ethers.formatEther(pendingRewards)} ETH`);
                const tx = await MonLsd.stakePending();
                await tx.wait();
            }

            // invoke handlePendingUndelegate
            let pendingUnstake = await MonLsd.pendingUnstake();
            if (pendingUnstake > 0) {
                console.log(`Handling pending undelegate: ${ethers.formatEther(pendingUnstake)} ETH`);
                const tx = await MonLsd.handlePendingUndelegate();
                await tx.wait();
            }
        }

        // invoke handleWithdraws
        let withdrawQueueLen = await MonLsd.withdrawQueueLen();
        if (withdrawQueueLen > 0) {
            let firstReady = await MonLsd.isFirstWithdrawItemReady.staticCall();
            if (!firstReady) return;
            console.log(`Handling withdraws, queue length: ${withdrawQueueLen}`);
            const tx = await MonLsd.handleWithdraws();
            await tx.wait();
        }
        
    }, 1000 * 60 * 5); // every 5 minutes
}

startMonadLsdService().catch(err => {
    console.error(err);
    process.exit(1);
});

const EPOCH_BLOCKS = 50000;

function boundaryBlock(epoch: bigint) {
    return epoch * BigInt(EPOCH_BLOCKS);
}

// Check if we are within the operate window (last 5000 blocks of the epoch)
function isInOperateWindow(currentBlock: number, epoch: bigint) {
    return boundaryBlock(epoch) - BigInt(currentBlock) <= BigInt(5000);
}