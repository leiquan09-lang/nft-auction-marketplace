const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AuctionHouseUpgradeable", function () {
  let owner, seller, bidder1, bidder2;
  let AuctionNFT, nft;
  let AuctionHouseUpgradeable, impl, proxy, auction;
  let MockAgg, ethAgg, usdAggToken;
  let erc20;

  beforeEach(async function () {
    [owner, seller, bidder1, bidder2] = await ethers.getSigners();

    // Deploy NFT
    AuctionNFT = await ethers.getContractFactory("AuctionNFT");
    nft = await AuctionNFT.deploy(owner.address);
    await nft.waitForDeployment();

    // Mint NFT to seller
    await nft.connect(owner).mint(seller.address, "ipfs://nft1");

    // Deploy Mock ETH/USD feed (8 decimals, 3000$)
    MockAgg = await ethers.getContractFactory("MockAggregator");
    ethAgg = await MockAgg.deploy(8, 3000n * 10n ** 8n);
    await ethAgg.waitForDeployment();

    // Deploy AuctionHouse implementation
    AuctionHouseUpgradeable = await ethers.getContractFactory("AuctionHouseUpgradeable");
    impl = await AuctionHouseUpgradeable.deploy();
    await impl.waitForDeployment();

    // Initialize via ERC1967Proxy
    const Proxy = await ethers.getContractFactory("ERC1967Proxy");
    const initData = impl.interface.encodeFunctionData("initialize", [owner.address, ethAgg.target]);
    proxy = await Proxy.deploy(impl.target, initData);
    await proxy.waitForDeployment();
    auction = AuctionHouseUpgradeable.attach(proxy.target);

    // Deploy SimpleERC20 as bidding token and set USD feed mock ($1)
    const ERC20 = await ethers.getContractFactory("SimpleERC20");
    erc20 = await ERC20.deploy("BidToken", "BID");
    await erc20.waitForDeployment();
    usdAggToken = await MockAgg.deploy(8, 1n * 10n ** 8n);
    await usdAggToken.waitForDeployment();
    await auction.connect(owner).setTokenUsdFeed(erc20.target, usdAggToken.target);
  });

  it("create auction and bid with ETH", async function () {
    // seller approves NFT and creates auction
    await nft.connect(seller).approve(auction.target, 0);
    await auction.connect(seller).createAuction(nft.target, 0, ethers.ZeroAddress, 3600);
    const auctionId = (await auction.nextAuctionId()) - 1n;

    // bidder1 bids 0.5 ETH
    await auction.connect(bidder1).bidEth(auctionId, { value: ethers.parseEther("0.5") });
    // bidder2 bids 0.6 ETH, refund bidder1
    await auction.connect(bidder2).bidEth(auctionId, { value: ethers.parseEther("0.6") });

    // fast-forward time
    await ethers.provider.send("evm_increaseTime", [4000]);
    await ethers.provider.send("evm_mine", []);

    // finalize
    await auction.connect(seller).finalize(auctionId);
    expect(await nft.ownerOf(0)).to.equal(bidder2.address);
  });

  it("create auction and bid with ERC20", async function () {
    // mint ERC20 to bidders
    await erc20.connect(owner).mint(bidder1.address, ethers.parseUnits("1000", 18));
    await erc20.connect(owner).mint(bidder2.address, ethers.parseUnits("1000", 18));

    // seller approves NFT
    await nft.connect(seller).approve(auction.target, 0);
    await auction.connect(seller).createAuction(nft.target, 0, erc20.target, 3600);
    const auctionId = (await auction.nextAuctionId()) - 1n;

    // bidder approvals
    await erc20.connect(bidder1).approve(auction.target, ethers.parseUnits("1000", 18));
    await erc20.connect(bidder2).approve(auction.target, ethers.parseUnits("1000", 18));

    await auction.connect(bidder1).bidErc20(auctionId, ethers.parseUnits("500", 18));
    await auction.connect(bidder2).bidErc20(auctionId, ethers.parseUnits("600", 18));

    await ethers.provider.send("evm_increaseTime", [4000]);
    await ethers.provider.send("evm_mine", []);

    const sellerBalBefore = await erc20.balanceOf(seller.address);
    await auction.connect(owner).finalize(auctionId);
    expect(await nft.ownerOf(0)).to.equal(bidder2.address);
    const expectedFee = ethers.parseUnits("600", 18) * 100n / 10000n; // 默认 1% 档
    const expectedNet = ethers.parseUnits("600", 18) - expectedFee; // 594 token
    expect(await erc20.balanceOf(seller.address)).to.equal(sellerBalBefore + expectedNet);
  });

  it("enforces min increment on ETH bids", async function () {
    await nft.connect(seller).approve(auction.target, 0);
    await auction.connect(seller).createAuction(nft.target, 0, ethers.ZeroAddress, 3600);
    const auctionId = (await auction.nextAuctionId()) - 1n;

    await auction.connect(bidder1).bidEth(auctionId, { value: ethers.parseEther("0.5") });
    // 2% 增幅，低于默认 5%，应失败
    await expect(
      auction.connect(bidder2).bidEth(auctionId, { value: ethers.parseEther("0.51") })
    ).to.be.revertedWith("increment too small");
    // 正好 5% 增幅，应成功
    await auction.connect(bidder2).bidEth(auctionId, { value: ethers.parseEther("0.525") });
  });

  it("supports seller cancellation before any bids", async function () {
    await nft.connect(seller).approve(auction.target, 0);
    await auction.connect(seller).createAuction(nft.target, 0, ethers.ZeroAddress, 3600);
    const auctionId = (await auction.nextAuctionId()) - 1n;

    await auction.connect(seller).cancel(auctionId);
    expect(await nft.ownerOf(0)).to.equal(seller.address);
  });

  it("deducts dynamic fee on finalize (ETH)", async function () {
    await nft.connect(seller).approve(auction.target, 0);
    const tx = await auction.connect(seller).createAuction(nft.target, 0, ethers.ZeroAddress, 3600);
    const rc = await tx.wait();
    const event = rc.logs.find(l => auction.interface.decodeEventLog("AuctionCreated", l.data, l.topics).auctionId !== undefined);
    const { auctionId } = auction.interface.decodeEventLog("AuctionCreated", event.data, event.topics);

    // 配置费率与阈值
    await auction.connect(owner).setFeeConfig(
      ethers.parseUnits("500", 18),
      ethers.parseUnits("1000", 18),
      100,
      50,
      20
    );

    // 出价 0.6 ETH，ETH/USD=3000 => 1800 USD，命中 0.2% 档
    await auction.connect(bidder1).bidEth(auctionId, { value: ethers.parseEther("0.6") });

    await ethers.provider.send("evm_increaseTime", [4000]);
    await ethers.provider.send("evm_mine", []);

    const sellerBalBefore = await ethers.provider.getBalance(seller.address);
    await auction.connect(owner).finalize(auctionId);
    const sellerBalAfter = await ethers.provider.getBalance(seller.address);

    const expectedFee = ethers.parseEther("0.6") * 20n / 10000n; // 0.0012 ETH
    const expectedNet = ethers.parseEther("0.6") - expectedFee; // 0.5988 ETH
    expect(sellerBalAfter - sellerBalBefore).to.equal(expectedNet);
  });

  it("deducts dynamic fee on finalize (ERC20)", async function () {
    await erc20.connect(owner).mint(bidder1.address, ethers.parseUnits("1000", 18));
    await erc20.connect(bidder1).approve(auction.target, ethers.parseUnits("1000", 18));

    await nft.connect(seller).approve(auction.target, 0);
    await auction.connect(seller).createAuction(nft.target, 0, erc20.target, 3600);
    const auctionId = (await auction.nextAuctionId()) - 1n;

    await auction.connect(owner).setFeeConfig(
      ethers.parseUnits("500", 18),
      ethers.parseUnits("1000", 18),
      100,
      50,
      20
    );

    await auction.connect(bidder1).bidErc20(auctionId, ethers.parseUnits("600", 18));

    await ethers.provider.send("evm_increaseTime", [4000]);
    await ethers.provider.send("evm_mine", []);

    const sellerBalBefore = await erc20.balanceOf(seller.address);
    await auction.connect(owner).finalize(auctionId);
    const sellerBalAfter = await erc20.balanceOf(seller.address);

    const expectedFee = ethers.parseUnits("600", 18) * 20n / 10000n; // 1.2 token
    const expectedNet = ethers.parseUnits("600", 18) - expectedFee; // 598.8 token
    expect(sellerBalAfter - sellerBalBefore).to.equal(expectedNet);
  });
});
