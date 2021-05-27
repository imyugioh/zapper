require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-ethers");
require("hardhat-gas-reporter");
require("solidity-coverage");
require("dotenv").config();

module.exports = {
  networks: {
    localhost: {
      url: "http://127.0.0.1:7545",
    },
    hardhat: {
      chainId: 1,
      forking: {
        url: `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
      },
      accounts: {
        mnemonic: process.env.MNEMONIC,
        accountsBalance: "1000000000000000000000000",
      },
      allowUnlimitedContractSize: true,
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: {
        mnemonic: process.env.MNEMONIC,
      },
      live: true,
      saveDeployments: true,
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: {
        mnemonic: process.env.MNEMONIC,
      },
      live: true,
      saveDeployments: true,
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_APIKEY,
  },
  solidity: {
    version: "0.6.12",
    settings: {
      optimizer: {
        enabled: true,
        runs: 9999,
      },
    },
  },
  mocha: {
    timeout: 20000000,
  },
  gasReporter: {
    enabled: false,
    coinmarketcap: process.env.COINMARKETCAP,
    currency: "USD",
    gasPrice: 61,
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
};
