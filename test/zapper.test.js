const hre = require("hardhat");
var chaiAsPromised = require("chai-as-promised");
const {assert} = require("chai").use(chaiAsPromised);
const {web3} = require("@openzeppelin/test-helpers/src/setup");

const IWETH = hre.artifacts.require("IWETH");
const IERC20 = hre.artifacts.require("IERC20");
const Zapper = hre.artifacts.require("Zapper");
const Vault = hre.artifacts.require("Vault");
const Controller = hre.artifacts.require("Controller");
const Strategy = hre.artifacts.require("Strategy");

const toWei = (amount, decimal = 18) => {
  return hre.ethers.utils.parseUnits(hre.ethers.BigNumber.from(amount).toString(), decimal);
};

const fromWei = (amount, decimal = 18) => {
  return hre.ethers.utils.formatUnits(amount, decimal);
};

const unlockAccount = async (address) => {
  await hre.network.provider.send("hardhat_impersonateAccount", [address]);
  return address;
};

describe("Zapper test", () => {
  let zapper, controller;
  let weth, usdt, wethSDT, wethUSDT;
  let usdtVault, wethSDTVault, wethUSDTVault;
  let usdtStrategy, wethSDTStrategy, wethUSDTStrategy;

  let whale, DAI, USDC;
  const whale_addr = "0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503";
  const WETH_ADDR = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
  const USDT_ADDR = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
  // const SDT_ADDR = "0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F";

  const WETH_SDT_PAIR = "0xc465C0a16228Ef6fE1bF29C04Fdb04bb797fd537";
  const WETH_USDT_PAIR = "0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852";

  before("deploy contracts", async () => {
    [alice, bob, craig] = await web3.eth.getAccounts();

    controller = await Controller.new(alice);
    zapper = await Zapper.new();

    usdtStrategy = await Strategy.new(USDT_ADDR, alice, controller.address);
    wethSDTStrategy = await Strategy.new(WETH_SDT_PAIR, alice, controller.address);
    wethUSDTStrategy = await Strategy.new(WETH_USDT_PAIR, alice, controller.address);

    usdtVault = await Vault.new(USDT_ADDR, false, alice, zapper.address, controller.address);
    wethSDTVault = await Vault.new(WETH_SDT_PAIR, true, alice, zapper.address, controller.address);
    wethUSDTVault = await Vault.new(WETH_USDT_PAIR, true, alice, zapper.address, controller.address);

    await controller.setVault(USDT_ADDR, usdtVault.address, {from: alice});
    await controller.setVault(WETH_SDT_PAIR, wethSDTVault.address, {from: alice});
    await controller.setVault(WETH_USDT_PAIR, wethUSDTVault.address, {from: alice});

    await controller.setStrategy(USDT_ADDR, usdtStrategy.address, {from: alice});
    await controller.setStrategy(WETH_SDT_PAIR, wethSDTStrategy.address, {from: alice});
    await controller.setStrategy(WETH_USDT_PAIR, wethUSDTStrategy.address, {from: alice});

    weth = await IWETH.at(WETH_ADDR);
    usdt = await IERC20.at(USDT_ADDR);

    wethSDT = await IERC20.at(WETH_SDT_PAIR);
    wethUSDT = await IERC20.at(WETH_USDT_PAIR);

    await weth.deposit({from: alice, value: toWei(10000)});
    await weth.deposit({from: bob, value: toWei(10000)});

    await web3.eth.sendTransaction({
      from: alice,
      to: whale_addr,
      value: toWei(10),
    });
    whale = await unlockAccount(whale_addr);

    DAI = await IERC20.at("0x6b175474e89094c44da98b954eedeac495271d0f");
    USDC = await IERC20.at("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48");

    await DAI.transfer(craig, toWei(10000), {from: whale});
    await USDC.transfer(alice, toWei(10000, 6), {from: whale});
  });

  it("alice zapper deposit test(single token)", async () => {
    const _wethBalance = await weth.balanceOf(alice);
    console.log("Alice's weth balance => ", _wethBalance.toString());

    console.log("Alice's usdt Vault token balance before => ", (await usdtVault.balanceOf(alice)).toString());
    await weth.approve(usdtVault.address, _wethBalance);
    await usdtVault.deposit(weth.address, _wethBalance);

    console.log("Alice's usdt Vault token balance after => ", (await usdtVault.balanceOf(alice)).toString());
  });

  it("alice usdt vault withdraw", async () => {
    console.log("Alice's usdt vault balance before => ", (await usdtVault.balanceOf(alice)).toString());
    console.log("Alice's usdt token balance before => ", (await usdt.balanceOf(alice)).toString());
    await usdtVault.withdrawAll();
    console.log("Alice's usdt vault balance after => ", (await usdtVault.balanceOf(alice)).toString());
    console.log("Alice's usdt token balance after => ", (await usdt.balanceOf(alice)).toString());
  });

  it("alice zapper deposit test(USDC)", async () => {
    const _usdcBalance = await USDC.balanceOf(alice);
    console.log("Alice's USDC balance before => ", _usdcBalance.toString());

    console.log("Alice's usdt Vault token balance before => ", (await usdtVault.balanceOf(alice)).toString());
    await USDC.approve(usdtVault.address, _usdcBalance);
    await usdtVault.deposit(USDC.address, _usdcBalance);

    console.log("Alice's USDC balance after => ", (await USDC.balanceOf(alice)).toString());

    console.log("Alice's usdt Vault token balance after => ", (await usdtVault.balanceOf(alice)).toString());
  });

  it("alice usdt vault withdraw", async () => {
    console.log("Alice's usdt vault balance before => ", (await usdtVault.balanceOf(alice)).toString());
    console.log("Alice's usdt token balance before => ", (await usdt.balanceOf(alice)).toString());
    await usdtVault.withdrawAll();
    console.log("Alice's usdt vault balance after => ", (await usdtVault.balanceOf(alice)).toString());
    console.log("Alice's usdt token balance after => ", (await usdt.balanceOf(alice)).toString());
  });

  it("bob zapper deposit test(lp token)", async () => {
    const _wethBalance = await weth.balanceOf(bob);
    console.log("Bob's weth balance => ", _wethBalance.toString());

    console.log("Bob's Weth/SDT Vault token balance before => ", (await wethSDTVault.balanceOf(bob)).toString());

    await weth.approve(wethSDTVault.address, _wethBalance, {from: bob});
    await wethSDTVault.deposit(weth.address, _wethBalance, {from: bob});

    console.log("Bob's Weth/SDT Vault token balance after => ", (await wethSDTVault.balanceOf(bob)).toString());
  });

  it("bob weth/sdt vault withdraw", async () => {
    console.log("Bob's weth/sdt vault balance before => ", (await wethSDTVault.balanceOf(bob)).toString());
    console.log("Bob's lp token balance before => ", (await wethSDT.balanceOf(bob)).toString());
    await wethSDTVault.withdrawAll({from: bob});
    console.log("Bob's weth/sdt vault balance after => ", (await wethSDTVault.balanceOf(bob)).toString());
    console.log("Bob's lp token balance after => ", (await wethSDT.balanceOf(bob)).toString());
  });

  it("craig weth/usdt deposit test(ETH)", async () => {
    let _ethBalance = await web3.eth.getBalance(craig);
    console.log("Craig's eth balance before => ", _ethBalance.toString());

    console.log("Craig's weth/usdt Vault token balance before => ", (await wethUSDTVault.balanceOf(craig)).toString());

    await wethUSDTVault.depositETH({from: craig, value: toWei(10000)});

    _ethBalance = await web3.eth.getBalance(craig);
    console.log("Craig's eth balance after => ", _ethBalance.toString());

    console.log("Craig's weth/usdt Vault token balance after => ", (await wethUSDTVault.balanceOf(craig)).toString());
  });

  it("craig weth/usdt vault withdraw", async () => {
    console.log("Craig's weth/usdt vault balance before => ", (await wethUSDTVault.balanceOf(craig)).toString());
    console.log("Craig's weth/usdt token balance before => ", (await wethUSDT.balanceOf(craig)).toString());
    await wethUSDTVault.withdrawAll({from: craig});
    console.log("Craig's weth/usdt vault balance after => ", (await wethUSDTVault.balanceOf(craig)).toString());
    console.log("Craig's weth/usdt token balance after => ", (await wethUSDT.balanceOf(craig)).toString());
  });

  it("craig weth/usdt deposit test(DAI)", async () => {
    const _daiBalance = await DAI.balanceOf(craig);
    console.log("Craig's DAI balance before => ", _daiBalance.toString());

    console.log("Craig's weth/usdt Vault token balance before => ", (await wethUSDTVault.balanceOf(craig)).toString());
    await DAI.approve(wethUSDTVault.address, _daiBalance, {from: craig});
    await wethUSDTVault.deposit(DAI.address, _daiBalance, {from: craig});

    console.log("Craig's DAI balance after => ", (await DAI.balanceOf(craig)).toString());
    console.log("Craig's weth/usdt Vault token balance after => ", (await wethUSDTVault.balanceOf(craig)).toString());
  });

  it("craig weth/usdt vault withdraw", async () => {
    console.log("Craig's weth/usdt vault balance before => ", (await wethUSDTVault.balanceOf(craig)).toString());
    console.log("Craig's weth/usdt token balance before => ", (await wethUSDT.balanceOf(craig)).toString());
    await wethUSDTVault.withdrawAll({from: craig});
    console.log("Craig's weth/usdt vault balance after => ", (await wethUSDTVault.balanceOf(craig)).toString());
    console.log("Craig's weth/usdt token balance after => ", (await wethUSDT.balanceOf(craig)).toString());
  });
});
