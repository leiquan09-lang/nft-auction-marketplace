# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.js
```

## Sepolia 部署配置（SimpleERC20）

- 前置要求：已安装依赖，项目可正常编译与测试（`npx hardhat compile` / `npx hardhat test`）
- 本项目使用 `hardhat-deploy` 管理部署流程，部署脚本位于 `deploy/001_deploy_simple_erc20.js`

### 1. 环境变量

- 按需设置以下环境变量（建议在终端会话中设置，避免将密钥写入仓库）：
  - `SEPOLIA_URL`：Sepolia RPC URL（Infura/Alchemy 等）
  - `PRIVATE_KEY`：部署账户私钥（不含 `0x` 前缀）

- macOS/Linux 示例：
  - `export SEPOLIA_URL=https://sepolia.infura.io/v3/<YOUR_KEY>`
  - `export PRIVATE_KEY=<YOUR_PRIVATE_KEY>`

- Windows PowerShell 示例：
  - `$env:SEPOLIA_URL="https://sepolia.infura.io/v3/<YOUR_KEY>"`
  - `$env:PRIVATE_KEY="<YOUR_PRIVATE_KEY>"`

> 说明：`hardhat.config.js` 会在检测到 `SEPOLIA_URL` 后自动启用 `sepolia` 网络配置。

### 2. 编译与部署

- 编译：`npx hardhat compile`
- 部署到 Sepolia：`npx hardhat deploy --network sepolia --tags SimpleERC20`
- 部署输出包含合约地址；亦可在 `deployments/sepolia` 目录中查看记录的地址与构造参数

### 3. 验证与交互

- 合约验证（可选）：
  - `npx hardhat verify --network sepolia <DEPLOYED_ADDRESS> "MyToken" "MTK"`

- 控制台交互（增发示例）：
  - `npx hardhat console --network sepolia`
  - 在控制台中执行：
    - `const t = await ethers.getContractAt("SimpleERC20", "<DEPLOYED_ADDRESS>")`
    - `await t.mint("<YOUR_ADDRESS>", ethers.parseUnits("1000", 18))`

### 4. 导入钱包

- 在钱包中添加自定义代币，填入部署的合约地址；符号默认 `MTK`、精度 `18`
- 余额更新后可直接在钱包界面查看，或通过区块浏览器确认 `Transfer`/`Approval` 事件

### 5. 注意事项

- 请勿将 `PRIVATE_KEY` 写入仓库或明文文件；推荐使用终端环境变量或安全的秘密管理方案
- Gas 成本取决于网络拥堵与 RPC 提供方的建议费用；部署前可在测试环境充分验证

## Task 2: 发行图文并茂的 NFT (MyNFT)

### 1. 准备 IPFS 元数据

1. **上传图片**
   - 准备一张图片。
   - 使用 [Pinata](https://www.pinata.cloud/) 或其他 IPFS 服务上传图片。
   - 获取图片的 IPFS URI (例如 `ipfs://QmYourImageHash`).

2. **创建元数据 JSON**
   - 创建一个 JSON 文件，内容如下：
     ```json
     {
       "name": "My Unique NFT",
       "description": "An awesome NFT on Sepolia",
       "image": "ipfs://QmYourImageHash",
       "attributes": [
         { "trait_type": "Background", "value": "Blue" }
       ]
     }
     ```
   - 将此 JSON 文件也上传到 IPFS。
   - 获取 JSON 的 IPFS URI (例如 `ipfs://QmYourMetadataHash`)。这就是后续铸造时需要的 `tokenURI`。

### 2. 部署合约 (MyNFT)

- 部署到 Sepolia：
  `npx hardhat deploy --network sepolia --tags MyNFT`

- 记下部署后的合约地址 `<DEPLOYED_ADDRESS>`。

### 3. 铸造 NFT

- 使用 Hardhat Task 铸造 NFT：
  ```bash
  npx hardhat mint-nft --network sepolia --contract <DEPLOYED_ADDRESS> --recipient <YOUR_WALLET_ADDRESS> --tokenuri ipfs://QmYourMetadataHash
  ```

### 4. 查看 NFT

> **注意**：OpenSea 已停止对测试网（Testnets）的支持，因此无法直接在 OpenSea 测试网上查看 Sepolia NFT。请使用以下替代方法：

1. **Etherscan (查看交易与合约)**
   - 访问 `https://sepolia.etherscan.io/address/<DEPLOYED_ADDRESS>`
   - 在 "Transactions" 标签页可以看到铸造记录。
   - 在 "Contract" -> "Read Contract" 标签页（如果已验证合约），调用 `tokenURI` 函数输入 `tokenId`（如 0），查看返回的 IPFS 链接。

2. **验证元数据 (手动)**
   - 获取 `tokenURI` 返回的链接（例如 `ipfs://Qm...`）。
   - 将 `ipfs://` 替换为网关地址，例如 `https://ipfs.io/ipfs/Qm...` 或 `https://gateway.pinata.cloud/ipfs/Qm...`。
   - 在浏览器中打开该链接，确认能看到 JSON 数据及图片链接。

3. **钱包查看 (MetaMask)**
   - **手机端**：MetaMask 手机 App 对 NFT 支持较好。切换到 Sepolia 网络，在 "NFT" 标签下选择 "Import NFT"，输入合约地址和 Token ID，即可显示图片和元数据。
   - **插件端**：部分版本支持，在 "NFT" 标签下尝试导入。

## Task 2 (作业 3): 讨饭合约 (BeggingContract)

### 1. 部署合约

- 部署到 Sepolia：
  `npx hardhat deploy --network sepolia --tags BeggingContract`

- 记下合约地址 `<DEPLOYED_ADDRESS>`。

### 2. 测试功能

1. **捐赠 (Donate)**
   - 在 Etherscan 上找到你的合约。
   - 连接钱包。
   - 调用 `donate` 函数，并在 `value` 字段输入想要捐赠的 ETH 数量（例如 0.001 ETH）。
   - 确认交易。

2. **查询捐赠 (Get Donation)**
   - 在 `Read Contract` 中调用 `getDonation`。
   - 输入你的钱包地址，应返回你捐赠的金额（单位 wei）。

3. **提款 (Withdraw)**
   - 只有合约部署者（Owner）可以调用。
-   在 `Write Contract` 中调用 `withdraw`。
-   确认交易，合约余额将全部转入你的钱包。

## Task 3: NFT 拍卖市场（升级 + 预言机）

### 概述

- 合约文件：
  - `contracts/task_three/AuctionNFT.sol`：基础 ERC721，支持设置每个 Token 的 URI。
  - `contracts/task_three/AuctionHouseUpgradeable.sol`：拍卖逻辑（UUPS 可升级）、支持 ETH/ERC20 出价与 Chainlink 价格预言机。
- 测试文件：`test/task_three/AuctionHouseUpgradeable.test.js`
- 部署脚本：`deploy/004_deploy_auction_house.js`

### 功能点

- 上架拍卖：将 NFT 转移到合约托管，记录拍卖参数。
- 出价：
  - 支持 ETH 出价（`payToken == address(0)`）
  - 支持 ERC20 出价（`payToken != address(0)`）
  - 内置“最小加价”规则，默认 `minIncrementBps = 500`（最低加价 5%）。
- 价格换算：
  - 使用 Chainlink ETH/USD 与 Token/USD 价格，将出价折算为 USD（18 位精度）以用于动态费率分档。
- 结束拍卖：
  - 成交后将 NFT 转给最高出价者
  - 资金按照“卖家净额 + 平台手续费”进行结算
- 撤单逻辑：
  - 卖家可在无任何出价时撤单，NFT 退回
  - 有出价后不可撤单（避免不公平与资金复杂度）
- 动态手续费：
  - 分档阈值与费率（基点）可配置：`setFeeConfig(th1, th2, bps1, bps2, bps3)`
  - 收费地址可配置：`setFeeRecipient(address)`（默认所有者）

### 参数配置

- `minIncrementBps`：最低加价比例（基点，10000=100%）
- `feeThreshold1Usd18 / feeThreshold2Usd18`：分档阈值（USD，18 位精度，如 `1000 ether` 表示 $1000）
- `feeBps1 / feeBps2 / feeBps3`：三档费率（基点）
- `ethUsdFeed`：Chainlink ETH/USD Aggregator 地址
- `tokenUsdFeed[token]`：某 ERC20 的 USD Aggregator 地址

### 示例（本地测试）

1. 安装依赖：
   - `npm install`
   - `npm install @openzeppelin/contracts-upgradeable`

2. 运行测试：
   - `npx hardhat test test/task_three/AuctionHouseUpgradeable.test.js`

3. 测试覆盖点：
   - ETH 与 ERC20 出价与退款
   - 最小加价限制（不满足则 revert "increment too small"）
   - 卖家撤单（在无出价情况下）
   - 动态手续费的卖家净额与平台收入

### 部署（Sepolia）

1. 设置环境变量：
   - `SEPOLIA_URL`、`PRIVATE_KEY`、`ETH_USD_FEED`
2. 执行部署：
   - `npx hardhat deploy --network sepolia --tags AuctionHouse`
3. 后续配置：
   - `setTokenUsdFeed(<ERC20>, <TOKEN_USD_FEED>)`
   - 根据业务需要，调用 `setFeeConfig` 与 `setMinIncrementBps`

### 设计要点

- 资金安全：
  - 所有退款与结算路径均带有失败检查（`require(ok, "...")`），避免资金丢失
  - 使用 `ReentrancyGuardUpgradeable` 防止重入
- 精度一致性：
  - 价格换算全部统一到 18 位精度，便于和 ETH/Token 金额做整数运算
- 可升级：
  - UUPS 模式，升级授权由 `owner` 控制
- 事件：
  - `AuctionCreated`、`BidPlaced`、`AuctionFinalized`，便于前端与索引服务追踪
