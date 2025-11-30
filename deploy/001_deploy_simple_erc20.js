module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  await deploy("SimpleERC20", {
    from: deployer,
    args: ["MyToken", "MTK"],
    log: true,
  });
  log("SimpleERC20 deployed");
};

module.exports.tags = ["SimpleERC20"];

