import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("StakingRewardModule", (m) => {
  const reward = m.contract("TokenStakingRewards", [process.env.cMON]);

  return { reward };
});
