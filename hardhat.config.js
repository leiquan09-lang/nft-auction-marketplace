require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
const { task } = require("hardhat/config");

task("mint-nft", "Mints a new NFT")
  .addParam("contract", "The address of the deployed contract")
  .addParam("recipient", "The address to receive the NFT")
  .addParam("tokenuri", "The token URI (IPFS URL)")
  .setAction(async (taskArgs, hre) => {
    const MyNFT = await hre.ethers.getContractFactory("MyNFT");
    const myNFT = MyNFT.attach(taskArgs.contract);
    console.log(`Minting NFT to ${taskArgs.recipient}...`);
    const tx = await myNFT.mintNFT(taskArgs.recipient, taskArgs.tokenuri);
    console.log(`Tx hash: ${tx.hash}`);
    await tx.wait();
    console.log("Transaction confirmed");
  });

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
