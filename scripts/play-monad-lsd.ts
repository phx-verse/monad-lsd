import { network } from "hardhat";

const { ethers } = await network.connect();
// const [sender] = await ethers.getSigners();

const MonLsd = await ethers.getContractAt("MonLsdUpgradeable", process.env.MON_LSD_ADDRESS!);

// const tx = await MonLsd.setCurrentValidatorId(1);
// await tx.wait();

// const tx2 = await MonLsd.setCMonAddress(process.env.cMON!);
// await tx2.wait();

// const tx = await MonLsd.deposit({
//     value: ethers.parseEther("0.01"),
// });
// await tx.wait();

// console.log("Deposited 0.01 ETH to MonLSD contract");

let apy = await MonLsd.poolAPY.staticCall();
console.log("Current pool APY:", apy.toString());
