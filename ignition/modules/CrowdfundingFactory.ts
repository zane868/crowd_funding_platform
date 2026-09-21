import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("CrowdfundingFactoryModule", (m) => {
  const factory = m.contract("CrowdfundingFactory");
  return { factory };
});
