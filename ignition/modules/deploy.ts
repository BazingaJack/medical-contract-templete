import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeployModule = buildModule("DeployModule", (m) => {

  const medical = m.contract("MedicalTemplate", []);

  return { medical };
});

export default DeployModule;