const { expect } = require("chai");
const { ethers } = require("hardhat");

// 用例说明：
// - 部署：校验合约所有者、名称与符号
// - 铸造：所有者可铸造、tokenId 连续增长、tokenURI 正确写入
// - 权限：非所有者铸造应被拒绝（OwnableUnauthorizedAccount）

describe("MyNFT Contract", function () {
  let MyNFT;
  let myNFT;
  let owner;
  let addr1;
  let addr2;

  // 每次测试前部署新实例，保证测试隔离
  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    MyNFT = await ethers.getContractFactory("MyNFT");
    // 部署合约，传入初始所有者地址
    myNFT = await MyNFT.deploy(owner.address);
    await myNFT.waitForDeployment();
  });

  describe("部署", function () {
    it("应设置正确的所有者", async function () {
      expect(await myNFT.owner()).to.equal(owner.address);
    });

    it("名称与符号应正确", async function () {
      expect(await myNFT.name()).to.equal("MyNFT");
      expect(await myNFT.symbol()).to.equal("MNFT");
    });
  });

  describe("铸造", function () {
    it("应为接收者铸造新的 NFT", async function () {
      const tokenURI = "ipfs://QmTestHash";
      await myNFT.mintNFT(addr1.address, tokenURI);

      expect(await myNFT.balanceOf(addr1.address)).to.equal(1);
      expect(await myNFT.ownerOf(0)).to.equal(addr1.address);
      expect(await myNFT.tokenURI(0)).to.equal(tokenURI);
    });

    it("Token ID 应正确递增", async function () {
      const tokenURI1 = "ipfs://QmTestHash1";
      const tokenURI2 = "ipfs://QmTestHash2";

      await myNFT.mintNFT(addr1.address, tokenURI1);
      await myNFT.mintNFT(addr2.address, tokenURI2);

      expect(await myNFT.ownerOf(0)).to.equal(addr1.address);
      expect(await myNFT.ownerOf(1)).to.equal(addr2.address);
    });

    it("非所有者尝试铸造应失败", async function () {
      const tokenURI = "ipfs://QmTestHash";
      await expect(
        myNFT.connect(addr1).mintNFT(addr2.address, tokenURI)
      ).to.be.revertedWithCustomError(myNFT, "OwnableUnauthorizedAccount"); // 中文含义：非所有者无权限
    });
  });
});
