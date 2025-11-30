const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BeggingContract", function () {
  let BeggingContract;
  let beggingContract;
  let owner;
  let donor1;
  let donor2;

  beforeEach(async function () {
    [owner, donor1, donor2] = await ethers.getSigners();
    BeggingContract = await ethers.getContractFactory("BeggingContract");
    beggingContract = await BeggingContract.deploy(owner.address);
    await beggingContract.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await beggingContract.owner()).to.equal(owner.address);
    });

    it("Should start with 0 balance", async function () {
      expect(await ethers.provider.getBalance(beggingContract.target)).to.equal(0);
    });
  });

  describe("Donations", function () {
    it("Should accept donations and update mapping", async function () {
      const donationAmount = ethers.parseEther("1.0");
      
      await expect(beggingContract.connect(donor1).donate({ value: donationAmount }))
        .to.emit(beggingContract, "Donation")
        .withArgs(donor1.address, donationAmount);

      expect(await beggingContract.getDonation(donor1.address)).to.equal(donationAmount);
      expect(await ethers.provider.getBalance(beggingContract.target)).to.equal(donationAmount);
    });

    it("Should accumulate donations from same donor", async function () {
      const amount1 = ethers.parseEther("1.0");
      const amount2 = ethers.parseEther("2.0");

      await beggingContract.connect(donor1).donate({ value: amount1 });
      await beggingContract.connect(donor1).donate({ value: amount2 });

      expect(await beggingContract.getDonation(donor1.address)).to.equal(amount1 + amount2);
    });

    it("Should fail if donation amount is 0", async function () {
      await expect(
        beggingContract.connect(donor1).donate({ value: 0 })
      ).to.be.revertedWith("Donation amount must be greater than 0");
    });
  });

  describe("Withdrawals", function () {
    it("Should allow owner to withdraw", async function () {
      const donationAmount = ethers.parseEther("10.0");
      await beggingContract.connect(donor1).donate({ value: donationAmount });

      const initialOwnerBalance = await ethers.provider.getBalance(owner.address);
      
      const tx = await beggingContract.connect(owner).withdraw();
      const receipt = await tx.wait();
      
      // Calculate gas cost
      const gasUsed = receipt.gasUsed * receipt.gasPrice;

      const finalOwnerBalance = await ethers.provider.getBalance(owner.address);
      
      // Owner balance should increase by donationAmount - gasUsed
      expect(finalOwnerBalance).to.equal(initialOwnerBalance + donationAmount - gasUsed);
      expect(await ethers.provider.getBalance(beggingContract.target)).to.equal(0);
    });

    it("Should fail if non-owner tries to withdraw", async function () {
      const donationAmount = ethers.parseEther("1.0");
      await beggingContract.connect(donor1).donate({ value: donationAmount });

      await expect(
        beggingContract.connect(donor1).withdraw()
      ).to.be.revertedWithCustomError(beggingContract, "OwnableUnauthorizedAccount");
    });

    it("Should fail if there are no funds to withdraw", async function () {
      await expect(
        beggingContract.connect(owner).withdraw()
      ).to.be.revertedWith("No funds to withdraw");
    });
  });
});
