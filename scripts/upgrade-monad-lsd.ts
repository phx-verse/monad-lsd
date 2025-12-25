import { network } from "hardhat";

const { ethers } = await network.connect();
const [sender] = await ethers.getSigners();

const ProxyAdmin = await ethers.getContractAt("ProxyAdmin", process.env.PROXY_ADMIN!);

console.log("Deploying new implementation of MonLsdUpgradeable...");
const monadLsdV2 = await ethers.deployContract("MonLsdUpgradeable");
await monadLsdV2.waitForDeployment();

const newImplAddress = monadLsdV2.target;

console.log("Upgrading Monad LSD to new implementation at:", newImplAddress);
const upgradeTx = await ProxyAdmin.upgradeAndCall(process.env.MON_LSD_ADDRESS!, newImplAddress, "0x", {
  from: sender.address,
});
await upgradeTx.wait();

console.log("Upgrade transaction hash:", upgradeTx.hash);
console.log("Monad LSD upgraded successfully to new implementation.");