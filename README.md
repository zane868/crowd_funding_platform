# Sample Hardhat 3 Project (`mocha` and `ethers`)

## 众筹工厂部署

工厂支持创建活动和查询活动列表。当前活动合约只有初始化和状态查询，尚未实现捐款、提款、退款。

先验证并在临时本地链试部署（进程退出后本地链状态不保留）：

```shell
npx hardhat build
npx tsc --noEmit
npm test
npm run deploy:local
```

部署到 Sepolia 前，在自己的终端交互式设置 RPC 和测试钱包私钥：

```shell
npx hardhat keystore set SEPOLIA_RPC_URL
npx hardhat keystore set SEPOLIA_PRIVATE_KEY
```

使用持有 Sepolia 测试 ETH 的测试钱包，不要将私钥写入源码或聊天。然后执行：

```shell
npm run deploy:sepolia
```

部署成功后，终端会输出工厂地址，Ignition 将部署记录保存到
`ignition/deployments/chain-11155111/`。可在 https://sepolia.etherscan.io 查询地址。
工厂不需要构造参数；调用 `createCampaign(name, goal, durationInDays)` 才会创建活动。
`goal` 单位为 wei，例如 `10000000000000000` 表示 `0.01 ETH`，持续时间范围为 1–90 天。

This project showcases a Hardhat 3 project using `mocha` for tests and the `ethers` library for Ethereum interactions.

To learn more about Hardhat 3, please visit the [Getting Started guide](https://hardhat.org/docs/getting-started#getting-started-with-hardhat-3). To share your feedback, join our [Hardhat 3](https://hardhat.org/hardhat3-telegram-group) Telegram group or [open an issue](https://github.com/NomicFoundation/hardhat/issues/new) in our GitHub issue tracker.

## Project Overview

This example project includes:

- A simple Hardhat configuration file.
- Foundry-compatible Solidity unit tests.
- TypeScript integration tests using `mocha` and ethers.js
- Examples demonstrating how to connect to different types of networks, including locally simulating OP mainnet.

## Usage

### Running Tests

To run all the tests in the project, execute the following command:

```shell
npx hardhat test
```

You can also selectively run the Solidity or `mocha` tests:

```shell
npx hardhat test solidity
npx hardhat test mocha
```

### Make a deployment to Sepolia

This project includes an example Ignition module to deploy the contract. You can deploy this module to a locally simulated chain or to Sepolia.

To run the deployment to a local chain:

```shell
npx hardhat ignition deploy ignition/modules/Counter.ts
```

To run the deployment to Sepolia, you need an account with funds to send the transaction. The provided Hardhat configuration includes a Configuration Variable called `SEPOLIA_PRIVATE_KEY`, which you can use to set the private key of the account you want to use.

You can set the `SEPOLIA_PRIVATE_KEY` variable using the `hardhat-keystore` plugin or by setting it as an environment variable.

To set the `SEPOLIA_PRIVATE_KEY` config variable using `hardhat-keystore`:

```shell
npx hardhat keystore set SEPOLIA_PRIVATE_KEY
```

After setting the variable, you can run the deployment with the Sepolia network:

```shell
npx hardhat ignition deploy --network sepolia ignition/modules/Counter.ts
```
