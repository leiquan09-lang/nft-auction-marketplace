const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MyNFT Contract", function () {
  let MyNFT;
  let myNFT;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    MyNFT = await ethers.getContractFactory("MyNFT");
    // 部署合约，传入初始所有者地址
    myNFT = await MyNFT.deploy(owner.address);
    await myNFT.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await myNFT.owner()).to.equal(owner.address);
    });

    it("Should have the correct name and symbol", async function () {
      expect(await myNFT.name()).to.equal("MyNFT");
      expect(await myNFT.symbol()).to.equal("MNFT");
    });
  });

  describe("Minting", function () {
    it("Should mint a new NFT to the recipient", async function () {
      const tokenURI = "ipfs://QmTestHash";
      await myNFT.mintNFT(addr1.address, tokenURI);

      expect(await myNFT.balanceOf(addr1.address)).to.equal(1);
      expect(await myNFT.ownerOf(0)).to.equal(addr1.address);
      expect(await myNFT.tokenURI(0)).to.equal(tokenURI);
    });

    it("Should increment token ID correctly", async function () {
      const tokenURI1 = "ipfs://QmTestHash1";
      const tokenURI2 = "ipfs://QmTestHash2";

      await myNFT.mintNFT(addr1.address, tokenURI1);
      await myNFT.mintNFT(addr2.address, tokenURI2);

      expect(await myNFT.ownerOf(0)).to.equal(addr1.address);
      expect(await myNFT.ownerOf(1)).to.equal(addr2.address);
    });

    it("Should fail if non-owner tries to mint", async function () {
      const tokenURI = "ipfs://QmTestHash";
      await expect(
        myNFT.connect(addr1).mintNFT(addr2.address, tokenURI)
      ).to.be.revertedWithCustomError(myNFT, "OwnableUnauthorizedAccount");
    });
  });
});
