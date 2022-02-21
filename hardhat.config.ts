import * as dotenv from "dotenv";

import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.4",
  networks: {
    rinkeby: {
      url: process.env.ALCHEMY_URL || "",
      accounts:
        process.env.PRIVATE_ACC_KEY !== undefined
          ? [process.env.PRIVATE_ACC_KEY]
          : [],
      gas: "auto",
      gasPrice: 30_000_000_000, // gwei
    },
    hardhat: {
      chainId: 31337,
    },
  },
};

export default config;
