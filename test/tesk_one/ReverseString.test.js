const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("task_one/ReverseString", function () {
  let rs;
  beforeEach(async function () {
    rs = await ethers.deployContract("ReverseString");
    await rs.waitForDeployment();
  });

  it("reverse 反转 ASCII 字符串与空串", async function () {
    expect(await rs.reverse("")) .to.equal("");
    expect(await rs.reverse("abc")).to.equal("cba");
  });

  it("romanToInt 将罗马数字转整数", async function () {
    expect(await rs.romanToInt("III")).to.equal(3n);
    expect(await rs.romanToInt("MCMXCIV")).to.equal(1994n);
  });

  it("intToRoman 将整数转罗马数字，并校验越界", async function () {
    expect(await rs.intToRoman(1994)).to.equal("MCMXCIV");
    await expect(rs.intToRoman(0)).to.be.revertedWith("out of range (1-3999)");
  });
});

