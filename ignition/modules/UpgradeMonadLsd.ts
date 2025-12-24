import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

import MonadModule from "./DeployMonadLsdUpgradeable.js";

export default buildModule("UpgradeMonadLsdModule", (m) => {
  const proxyAdminOwner = m.getAccount(0);

  const { proxyAdmin, monadLsd: proxy } = m.useModule(MonadModule);

  const V2 = m.contract("MonLsdUpgradeable");
  
  m.call(proxyAdmin, "upgradeAndCall", [proxy, V2, "0x"], {
    from: proxyAdminOwner,
  });

  return { proxyAdmin, proxy };
});