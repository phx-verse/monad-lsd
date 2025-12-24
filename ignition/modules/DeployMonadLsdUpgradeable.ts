import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("MonLsdUpgradeableModule", (m) => {
  const proxyAdminOwner = m.getAccount(0);

  // deploy cMon contract
  const cMon = m.contract("CompoundMon", [proxyAdminOwner]);

  // deploy MonLsd implementation
  const MonLsdImpl = m.contract("MonLsdUpgradeable");

  // deploy TransparentUpgradeableProxy pointing to MonLsd implementation
  const encodedFunctionCall = m.encodeFunctionCall(MonLsdImpl, "initialize");
  const proxy = m.contract("TransparentUpgradeableProxy", [
    MonLsdImpl,
    proxyAdminOwner,
    encodedFunctionCall,
  ]);

  // set cMon's lsd_contract to the proxy address
  m.call(cMon, "setLsd", [proxy]);

  // read proxyAdmin from event
  const proxyAdminAddress = m.readEventArgument(
    proxy,
    "AdminChanged",
    "newAdmin",
  );

  //
  const proxyAdmin = m.contractAt("ProxyAdmin", proxyAdminAddress);

  return { proxyAdmin, monadLsd: proxy, cMon };
});