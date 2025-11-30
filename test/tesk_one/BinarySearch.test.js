const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("task_one/BinarySearch", function () {
  let bs;
  beforeEach(async function () {
    bs = await ethers.deployContract("BinarySearch");
    await bs.waitForDeployment();
  });

  it("binarySearch 命中返回索引，未命中返回 -1", async function () {
    const arr = [1, 3, 5, 7, 9];
    expect(await bs.binarySearch(arr, 5)).to.equal(2n);
    expect(await bs.binarySearch(arr, 8)).to.equal(-1n);
    expect(await bs.binarySearch([], 1)).to.equal(-1n);
  });

  it("binarySearchWithFlag 返回 (found, index)", async function () {
    const arr = [2, 4, 6, 8];
    const [found1, idx1] = await bs.binarySearchWithFlag(arr, 6);
    expect(found1).to.equal(true);
    expect(idx1).to.equal(2n);

    const [found2, idx2] = await bs.binarySearchWithFlag(arr, 7);
    expect(found2).to.equal(false);
    expect(idx2).to.equal(0n);
  });
});

