import { network } from "hardhat";

const { ethers } = await network.connect();

let deployTx = await ethers.deployContract("TokenStakingRewards", [process.env.cMON]);
await deployTx.waitForDeployment();

console.log(
  `TokenStakingRewards deployed to: ${deployTx.target}`
);