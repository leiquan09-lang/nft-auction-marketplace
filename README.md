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
