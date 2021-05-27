async function main() {
  const deployer = "0x2E9c7a211deC8209762b0A2665Ce387286479c56";

  const want = "0xdAC17F958D2ee523a2206206994597C13D831ec7"; //usdt

  const ControllerFactory = await ethers.getContractFactory("Controller");
  const Controller = await ControllerFactory.deploy(deployer);
  console.log("Controller deployed at ", Controller.address);

  const ZapperFactory = await ethers.getContractFactory("Zapper");
  const Zapper = await ZapperFactory.deploy();
  console.log("Zapper deployed at ", Zapper.address);

  const VaultFactory = await ethers.getContractFactory("Vault");
  const Vault = await VaultFactory.deploy(want, false, deployer, Zapper.address, Controller.address);
  console.log("Vault deployed at ", Vault.address);

  const StrategyFactory = await ethers.getContractFactory("Strategy");
  const Strategy = await StrategyFactory.deploy(want, deployer, Controller.address);
  console.log("Strategy deployed at ", Strategy.address);

  await Controller.setVault(want, Vault.address);
  console.log("Vault is set to controller");
  await Controller.setStrategy(want, Strategy.address);
  console.log("Strategy is set to controller");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
