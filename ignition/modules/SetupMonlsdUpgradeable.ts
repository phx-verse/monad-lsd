import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

import MonadLsdUpgradeableModule from "./DeployMonadLsdUpgradeable.js";

export default buildModule("SetupMonLsd", (m) => {
  const { monadLsd, cMon } = m.useModule(MonadLsdUpgradeableModule);

  const monLsd = m.contractAt("MonLsdUpgradeable", monadLsd);
  m.call(monLsd, "setCMonAddress", [cMon]);
  m.call(monLsd, "setCurrentValidatorId", [parseInt(process.env.VALIDATOR_ID || "0")]);

  return { monLsd };
});