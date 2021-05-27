const hre = require("hardhat");
var chaiAsPromised = require("chai-as-promised");
const { assert } = require("chai").use(chaiAsPromised);
const { time } = require("@openzeppelin/test-helpers");
const { web3 } = require("@openzeppelin/test-helpers/src/setup");

const IWETH = hre.artifacts.require("IWETH");
const IERC20 = hre.artifacts.require("IERC20");
const Zapper = hre.artifacts.require("Zapper");
const Vault = hre.artifacts.require("Vault");

const toWei = (amount, decimal = 18) => {
  return hre.ethers.utils.parseUnits(
    hre.ethers.BigNumber.from(amount).toString(),
    decimal
  );
};

describe("Zapper test", () => {
  let weth, vault, zapper;
  const WETH_ADDR = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
  const USDT_ADDR = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
  const USDC_ADDR = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
  const DAI_ADDR = "0x6B175474E89094C44Da98b954EedeAC495271d0F";

  before("deploy contracts", async () => {
    [alice, bob, craig] = await web3.eth.getAccounts();

    vault = await Vault.new();
    zapper = await Zapper.new(vault.address);
    await vault.setZapper(zapper.address);

    weth = await IWETH.at(WETH_ADDR);
    await weth.deposit({ from: alice, value: toWei(1000) });
    await weth.deposit({ from: bob, value: toWei(1000) });
  });

  it("alice zapper single deposit test", async () => {
    const _wethBalance = await weth.balanceOf(alice);

    console.log("Alice's weth balance => ", _wethBalance.toString());

    await weth.approve(zapper.address, _wethBalance);
    await zapper.ZapInSingle(WETH_ADDR, USDC_ADDR, _wethBalance); //want USDC by depositing weth
    const _vaultbalance = await vault.balanceOf(alice);

    console.log("Alice's vault token balance => ", _vaultbalance.toString());
  });

  it("bob zapper multi deposit test", async () => {
    const _wethBalance = await weth.balanceOf(bob);

    console.log("Bob's weth balance => ", _wethBalance.toString());

    await weth.approve(zapper.address, _wethBalance, { from: bob });
    await zapper.ZapInMultiple(WETH_ADDR, WETH_ADDR, USDC_ADDR, _wethBalance, {
      from: bob,
    }); //want WETH/USDC lp by depositing WETH

    const _vaultbalance = await vault.balanceOf(bob);
    console.log("Bob's vault token balance => ", _vaultbalance.toString());
  });
});
