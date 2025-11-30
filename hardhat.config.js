require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");

/** @type import('hardhat/config').HardhatUserConfig */
const networks = {};
if (process.env.SEPOLIA_URL) {
  networks.sepolia = {
    url: process.env.SEPOLIA_URL,
    accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
  };
}

module.exports = {
  solidity: "0.8.28",
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  networks,
};
