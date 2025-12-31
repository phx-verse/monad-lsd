import { network } from "hardhat";

const { ethers } = await network.connect();

let tokenRewardContract = await ethers.getContractAt("TokenStakingRewards", process.env.TOKEN_REWARD_ADDRESS!);

const duration = 60 * 60 * 24 * 7; // 7 days in seconds
const amount = "1000";

let tx = await tokenRewardContract.setRewardRate(duration, { value: ethers.parseEther(amount) });
await tx.wait();

console.log(`Token reward duration set to ${duration} seconds and notified reward amount of ${amount} tokens.`);