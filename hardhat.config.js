require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("dotenv").config();
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

const sepoliaUrl =
  process.env.SEPOLIA_URL ||
  (process.env.INFURA_API_KEY
    ? `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`
    : "");

const privateKey = process.env.PRIVATE_KEY || process.env.PK;

if (sepoliaUrl) {
  networks.sepolia = {
    url: sepoliaUrl,
    accounts: privateKey ? [privateKey] : [],
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
