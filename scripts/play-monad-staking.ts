// @ts-ignore
import MonadStakingAbi from '../res/MonadStakingAbi.json' with { type: 'json' };
import { network } from "hardhat";

const { ethers } = await network.connect();
const [sender] = await ethers.getSigners();

const STAKING_CONTRACT_ADDRESS = "0x0000000000000000000000000000000000001000";
const Staking = await ethers.getContractAt(MonadStakingAbi, STAKING_CONTRACT_ADDRESS);

// @ts-ignore
let epoch = await Staking.getEpoch();
console.log("Current epoch:", epoch);

// @ts-ignore
let deleInfo = await Staking.getDelegator(6, '0x7deFad05B632Ba2CeF7EA20731021657e20a7596');
console.log("Delegator info:", deleInfo);

// @ts-ignore
let withdrawInfo = await Staking.getWithdrawalRequest(6, "0x7deFad05B632Ba2CeF7EA20731021657e20a7596", 1);
console.log("Withdrawal info:", withdrawInfo);