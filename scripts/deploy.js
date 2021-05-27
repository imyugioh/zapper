async function main() {
  const VaultFactory = await ethers.getContractFactory("Vault");
  const Vault = await VaultFactory.deploy();
  console.log("Vault deployed at ", Vault.address);

  const ZapperFactory = await ethers.getContractFactory("Zapper");
  const Zapper = await ZapperFactory.deploy(Vault.address);
  console.log("Zapper deployed at ", Zapper.address);

  await Vault.setZapper(Zapper.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
