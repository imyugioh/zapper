async function main() {
  const SaffronERC20Staking = await ethers.getContractFactory(
    "SaffronERC20Staking"
  );
  const saffronStaking = await SaffronERC20Staking.deploy();
  console.log("SaffronERC20Staking deployed to:", saffronStaking.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
