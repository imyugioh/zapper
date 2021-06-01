# Zapper contracts

## Getting Started

You need to install hardhat and openzeppelin packages.

```bash
npm install
```

## Setup

Create an environment file named `.env` and fill the next environment variables.

```
ETHERSCAN_APIKEY=YOUR ETHERSCAN API KEY
MNEMONIC=YOUR MNEMONIC
INFURA_KEY=YOUR INFURA KEY
COINMARKETCAP=YOUR COINMARKETCAP API KEY
```

## Build

```bash
npm run compile
```

## Deployments

You can see the available scripts located at `package.json`.

### Rinkeby deployment

```bash
npm run deploy:rinkeby
```

### Mainnet deployment

```bash
npm run deploy:mainnet
```

## Test

```bash
npm run test
```

We are using the solidity version 0.6.12.
