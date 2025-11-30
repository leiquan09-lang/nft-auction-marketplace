const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("task_one/MergeSortedArray", function () {
  let msa;
  beforeEach(async function () {
    msa = await ethers.deployContract("MergeSortedArray");
    await msa.waitForDeployment();
  });

  it("merge 合并两个升序数组", async function () {
    const a = [1, 3, 5];
    const b = [2, 4, 6];
    const res = await msa.merge(a, b);
    expect(res).to.deep.equal([1n, 2n, 3n, 4n, 5n, 6n]);
  });

  it("mergeInto 就地合并到 a", async function () {
    const a = [1, 3, 5, 0, 0, 0];
    const b = [2, 4, 6];
    const res = await msa.mergeInto(a, 3, b, 3);
    expect(res).to.deep.equal([1n, 2n, 3n, 4n, 5n, 6n]);
  });
});

