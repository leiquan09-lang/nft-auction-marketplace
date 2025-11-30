const { expect } = require("chai");
const { ethers } = require("hardhat");

// 用例说明：
// - 部署后应设置正确的所有者地址
// - donate：接受捐赠、累加捐赠金额、触发 Donation 事件
// - withdraw：仅所有者可提取所有余额，非所有者调用应失败；无余额时应失败
// - getDonation：可查询任意地址累计捐赠金额

describe("BeggingContract", function () {
  let BeggingContract;
  let beggingContract;
  let owner;
  let donor1;
  let donor2;

  // 在每个测试前部署一个全新的合约实例，保证测试相互独立
  beforeEach(async function () {
    [owner, donor1, donor2] = await ethers.getSigners();
    BeggingContract = await ethers.getContractFactory("BeggingContract");
    beggingContract = await BeggingContract.deploy(owner.address);
    await beggingContract.waitForDeployment();
  });

  describe("部署", function () {
    it("应设置正确的所有者", async function () {
      expect(await beggingContract.owner()).to.equal(owner.address);
    });

    it("初始余额应为 0", async function () {
      expect(await ethers.provider.getBalance(beggingContract.target)).to.equal(0);
    });
  });

  describe("捐赠", function () {
    it("应接受捐赠并更新映射", async function () {
      const donationAmount = ethers.parseEther("1.0");
      
      await expect(beggingContract.connect(donor1).donate({ value: donationAmount }))
        .to.emit(beggingContract, "Donation")
        .withArgs(donor1.address, donationAmount);

      expect(await beggingContract.getDonation(donor1.address)).to.equal(donationAmount);
      expect(await ethers.provider.getBalance(beggingContract.target)).to.equal(donationAmount);
    });

    it("同一捐赠者的捐赠应累加", async function () {
      const amount1 = ethers.parseEther("1.0");
      const amount2 = ethers.parseEther("2.0");

      await beggingContract.connect(donor1).donate({ value: amount1 });
      await beggingContract.connect(donor1).donate({ value: amount2 });

      expect(await beggingContract.getDonation(donor1.address)).to.equal(amount1 + amount2);
    });

    it("捐赠金额为 0 时应失败", async function () {
      await expect(
        beggingContract.connect(donor1).donate({ value: 0 })
      ).to.be.revertedWith("捐赠金额必须大于 0");
    });
  });

  describe("提款", function () {
    it("应允许所有者提款", async function () {
      const donationAmount = ethers.parseEther("10.0");
      await beggingContract.connect(donor1).donate({ value: donationAmount });

      const initialOwnerBalance = await ethers.provider.getBalance(owner.address);
      
      const tx = await beggingContract.connect(owner).withdraw();
      const receipt = await tx.wait();
      
      // 计算 gas 成本，作为预期值的一部分
      const gasUsed = receipt.gasUsed * receipt.gasPrice;

      const finalOwnerBalance = await ethers.provider.getBalance(owner.address);
      
      // 断言：所有者余额增加了捐赠金额扣除交易消耗的 gas
      expect(finalOwnerBalance).to.equal(initialOwnerBalance + donationAmount - gasUsed);
      expect(await ethers.provider.getBalance(beggingContract.target)).to.equal(0);
    });

    it("非所有者提款应失败", async function () {
      const donationAmount = ethers.parseEther("1.0");
      await beggingContract.connect(donor1).donate({ value: donationAmount });

      await expect(
        beggingContract.connect(donor1).withdraw()
      ).to.be.revertedWithCustomError(beggingContract, "OwnableUnauthorizedAccount"); // 中文含义：非所有者无权限
    });

    it("无资金可提取时应失败", async function () {
      await expect(
        beggingContract.connect(owner).withdraw()
      ).to.be.revertedWith("无可提取资金");
    });
  });
});
