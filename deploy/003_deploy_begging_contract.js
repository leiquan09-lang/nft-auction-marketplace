module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  console.log("Deploying BeggingContract with account:", deployer);

  await deploy("BeggingContract", {
    from: deployer,
    args: [deployer], // 构造函数参数：initialOwner
    log: true,
    waitConfirmations: 1,
  });
};

module.exports.tags = ["BeggingContract"];
