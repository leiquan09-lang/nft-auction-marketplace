module.exports = async ({ getNamedAccounts, deployments, ethers }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  log("Deploying AuctionHouseUpgradeable implementation...");
  const impl = await deploy("AuctionHouseUpgradeable_impl", {
    from: deployer,
    log: true,
    waitConfirmations: 1,
  });

  const ethUsdFeed = process.env.ETH_USD_FEED || ethers.ZeroAddress;
  const factory = await ethers.getContractFactory("AuctionHouseUpgradeable");
  const initData = factory.interface.encodeFunctionData("initialize", [deployer, ethUsdFeed]);

  log("Deploying ERC1967Proxy for AuctionHouseUpgradeable...");
  const proxy = await deploy("AuctionHouseUpgradeable_Proxy", {
    from: deployer,
    contract: "ERC1967Proxy",
    args: [impl.address, initData],
    log: true,
    waitConfirmations: 1,
  });

  log(`AuctionHouse Proxy deployed at: ${proxy.address}`);
};

module.exports.tags = ["AuctionHouse"];

