import { network } from "hardhat";

const { ethers } = await network.connect();

const StakingReward = await ethers.getContractAt("TokenStakingRewards", process.env.STAKING_REWARD!);

const tx = await StakingReward.setRewardRate(60 * 60 * 24 * 7, {
    value: ethers.parseEther("1"),
});

await tx.wait();

console.log("Staking reward rate set for weekly distribution with 1 ETH funding.");