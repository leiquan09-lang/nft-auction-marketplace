const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Voting", function () {
  let voting;

  beforeEach(async function () {
    voting = await ethers.deployContract("Voting");
    await voting.waitForDeployment();
  });

  it("初始候选人的票数为 0", async function () {
    const alice = ethers.encodeBytes32String("Alice");
    expect(await voting.getVotes(alice)).to.equal(0n);
  });

  it("投票应增加候选人的票数并发出事件", async function () {
    const bob = ethers.encodeBytes32String("Bob");
    await expect(voting.vote(bob))
      .to.emit(voting, "Voted")
      .withArgs(bob, 1n);
    expect(await voting.getVotes(bob)).to.equal(1n);
    await voting.vote(bob);
    expect(await voting.getVotes(bob)).to.equal(2n);
  });

  it("不同候选人分别计数", async function () {
    const alice = ethers.encodeBytes32String("Alice");
    const bob = ethers.encodeBytes32String("Bob");
    await voting.vote(alice);
    await voting.vote(bob);
    await voting.vote(bob);
    expect(await voting.getVotes(alice)).to.equal(1n);
    expect(await voting.getVotes(bob)).to.equal(2n);
  });

  it("resetVotes 重置所有候选人的票数并发出事件", async function () {
    const alice = ethers.encodeBytes32String("Alice");
    const bob = ethers.encodeBytes32String("Bob");
    await voting.vote(alice);
    await voting.vote(bob);
    await expect(voting.resetVotes()).to.emit(voting, "Reset");
    expect(await voting.getVotes(alice)).to.equal(0n);
    expect(await voting.getVotes(bob)).to.equal(0n);
  });
});

