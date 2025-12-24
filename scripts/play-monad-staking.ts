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
let deleInfo = await Staking.getDelegator(1, '0x1d6386e7b848C379C9CB2fF29275994d5e9BD382');
console.log("Delegator info:", deleInfo);