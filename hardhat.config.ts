import 'solidity-coverage';
import { HardhatUserConfig, task } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import '@openzeppelin/hardhat-upgrades';
import '@nomiclabs/hardhat-web3';
import 'hardhat-watcher';
import 'hardhat-deploy';
import '@atixlabs/hardhat-time-n-mine';
import '@nomicfoundation/hardhat-chai-matchers';
import 'hardhat-gas-reporter';

import { EthGasReporterConfig } from 'hardhat-gas-reporter/dist/src/types';

import { accounts, node_url } from './utils/network';

const gasReporter: EthGasReporterConfig = {
  enabled: true,
  outputFile: 'gas-usage.txt',
  currency: 'USD',
  noColors: true,
  coinmarketcap: process.env.COINMARKETCAP_API_KEY,
  token: 'BNB',
};

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.9',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  gasReporter,
  namedAccounts: {
    deployer: {
      default: 0, // '0x3bC45964020373E05728A02591d74b4E484D6481',
    },
    verifier: {
      default: 1
    },
    universal: {
      default: '0x5f1BcFf513a637c564B52643b3E2EC218C7b1F91',
    },
  },

  mocha: {
    timeout: 100000000
  },

  networks: {
    hardhat: {
      chainId: process.env.HARDHAT_FORK_CHAINID
        ? parseInt(process.env.HARDHAT_FORK_CHAINID)
        : 31337,
      // process.env.HARDHAT_FORK will specify the network that the fork is made from.
      // this line ensure the use of the corresponding accounts
      accounts: accounts(process.env.HARDHAT_FORK),
      forking: process.env.HARDHAT_FORK
        ? {
          // TODO once PR merged : network: process.env.HARDHAT_FORK,
          url: node_url(process.env.HARDHAT_FORK),
          blockNumber: process.env.HARDHAT_FORK_NUMBER
            ? parseInt(process.env.HARDHAT_FORK_NUMBER)
            : undefined,
        }
        : undefined,
      // mining: {
      //   auto: false,
      //   interval: 3000,
      // }
      allowUnlimitedContractSize: true,
    },
    localhost: {
      url: node_url('localhost'),
      accounts: accounts(),
    },
    staging: {
      url: node_url('rinkeby'),
      accounts: accounts('rinkeby'),
    },
    production: {
      url: node_url('mainnet'),
      accounts: accounts('mainnet'),
    },
    mainnet: {
      url: node_url('mainnet'),
      accounts: accounts('mainnet'),
    },
    rinkeby: {
      url: node_url('rinkeby'),
      accounts: accounts('rinkeby'),
    },
    kovan: {
      url: node_url('kovan'),
      accounts: accounts('kovan'),
    },
    goerli: {
      url: node_url('goerli'),
      accounts: accounts('goerli'),
    },

    bsc_testnet: {
      url: node_url('bsc_testnet'),
      accounts: accounts('bsc_testnet'),
    },

    bsc_mainnet: {
      url: node_url('bsc_mainnet'),
      accounts: accounts('bsc_mainnet'),
    },
    fuji_testnet: {
      url: node_url('fuji_testnet'),
      accounts: accounts('fuji_testnet'),
    },

    cube_testnet: {
      url: node_url('cube_testnet'),
      accounts: accounts('cube_testnet'),
    },

    cro_testnet: {
      url: node_url('cro_testnet'),
      accounts: accounts('cro_testnet'),
      chainId: 338,
    },
  },

  watcher: {
    compilation: {
      tasks: ['compile'],
      files: ['./contracts'],
      ignoredFiles: ['**/.vscode'],
      verbose: true,
      clearOnStart: true,
      start: 'echo Running my compilation task now..',
    },
    ci: {
      files: ['./test', './contracts'],
      tasks: [
        'clean',
        'compile',
        // { command: 'compile', params: { quiet: true } },
        { command: 'test', params: { noCompile: true } },
      ],
      clearOnStart: true,
    },
  },

  // deterministicDeployment: {
  //   "4": {
  //     factory: "<factory_address>",
  //     deployer: "<deployer_address>",
  //     funding: "<required_funding_in_wei>",
  //     signedTx: "<raw_signed_tx>",
  //   }
  // }

  etherscan: {
    apiKey: "V6I4M6SFC3DNP6TPVRDDD7IYQ95URXT47J",
  },
};

export default config;
