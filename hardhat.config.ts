import hardhatToolboxMochaEthersPlugin from "@nomicfoundation/hardhat-toolbox-mocha-ethers";
import { configVariable, defineConfig } from "hardhat/config";
import "dotenv/config";

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";

export default defineConfig({
  plugins: [hardhatToolboxMochaEthersPlugin],
  solidity: {
    npmFilesToBuild: [
      "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol",
      "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol",
    ],
    profiles: {
      default: {
        version: "0.8.28",
      },
      production: {
        version: "0.8.28",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    },
  },
  networks: {
    hardhatMainnet: {
      type: "edr-simulated",
      chainType: "l1",
    },
    hardhatOp: {
      type: "edr-simulated",
      chainType: "op",
    },
    sepolia: {
      type: "http",
      chainType: "l1",
      url: configVariable("SEPOLIA_RPC_URL"),
      accounts: [configVariable("SEPOLIA_PRIVATE_KEY")],
    },
    monad: {
      type: "http",
      chainType: "l1",
      url: configVariable("MONAD_RPC_URL"),
      accounts: {
        mnemonic: configVariable("ACCOUNTS_MNEMONIC"), 
        path: "m/44'/60'/0'/0",
        initialIndex: 0,
        count: 10,
        passphrase: configVariable("ACCOUNTS_PASSPHRASE"),
      },
    },
    monadTest: {
      type: "http",
      chainType: "l1",
      url: configVariable("MONAD_TEST_RPC_URL"),
      accounts: [configVariable("MONAD_TEST_PRIVATE_KEY")],
    },
  },
  verify: {
    blockscout: {
      enabled: false,
    },
    etherscan: {
      enabled: true,
      apiKey: ETHERSCAN_API_KEY,
    },
    sourcify: {
      enabled: true,
      apiUrl: "https://sourcify-api-monad.blockvision.org",
    },
  },
  chainDescriptors: {
    143: {
      name: "MonadMainnet",
      blockExplorers: {
        etherscan: {
          name: "Monadscan",
          url: "https://monadscan.com",
          apiUrl: "https://api.etherscan.io/v2/api",
        },
      },
    },
  }
});
