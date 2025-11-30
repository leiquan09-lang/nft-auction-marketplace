const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("task_two/SimpleERC20", function () {
  let token, owner, user1, user2;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();
    token = await ethers.deployContract("SimpleERC20", ["MyToken", "MTK"]);
    await token.waitForDeployment();
  });

  it("mint 仅限所有者，余额与总供给更新，触发事件", async function () {
    await expect(token.connect(user1).mint(user1.address, 100n)).to.be.revertedWith("not owner");
    await expect(token.mint(owner.address, 100n))
      .to.emit(token, "Transfer")
      .withArgs(ethers.ZeroAddress, owner.address, 100n);
    expect(await token.totalSupply()).to.equal(100n);
    expect(await token.balanceOf(owner.address)).to.equal(100n);
  });

  it("transfer 余额变化与事件", async function () {
    await token.mint(owner.address, 200n);
    await expect(token.transfer(user1.address, 50n))
      .to.emit(token, "Transfer")
      .withArgs(owner.address, user1.address, 50n);
    expect(await token.balanceOf(owner.address)).to.equal(150n);
    expect(await token.balanceOf(user1.address)).to.equal(50n);
  });

  it("approve 与 transferFrom 扣减授权与余额，触发事件", async function () {
    await token.mint(owner.address, 300n);
    await expect(token.approve(user1.address, 120n))
      .to.emit(token, "Approval")
      .withArgs(owner.address, user1.address, 120n);
    expect(await token.allowance(owner.address, user1.address)).to.equal(120n);

    await expect(token.connect(user1).transferFrom(owner.address, user2.address, 100n))
      .to.emit(token, "Transfer")
      .withArgs(owner.address, user2.address, 100n);
    expect(await token.balanceOf(owner.address)).to.equal(200n);
    expect(await token.balanceOf(user2.address)).to.equal(100n);
    expect(await token.allowance(owner.address, user1.address)).to.equal(20n);
  });
});

