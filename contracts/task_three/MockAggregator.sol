// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 说明：
// 本合约为 Chainlink AggregatorV3 的最小替身（Mock），仅用于本地/CI 测试。
// 作用：为需要 USD 价格换算的业务（如拍卖动态手续费）提供可控的价格数据。
// 特点：
// - 支持设置价格精度（decimals）与当前价格（answer）
// - 提供与 AggregatorV3Interface 同名的关键方法（decimals、latestRoundData）以便兼容
// - 接口简化，仅保留测试所需方法；不维护真实的轮次/历史数据

// 与 Chainlink 的接口保持一致的最小子集，方便在业务中直接替换引用
interface AggregatorV3InterfaceLike {
    // 返回价格精度（小数位数）。例如 8 表示价格以 10^8 为精度。
    function decimals() external view returns (uint8);
    // 返回价格数据的元组：
    // (roundId, answer, startedAt, updatedAt, answeredInRound)
    // 为了测试简化，这里仅 answer 与 updatedAt 有意义，其余填充占位值。
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

contract MockAggregator is AggregatorV3InterfaceLike {
    // 价格精度（与 Chainlink 保持一致语义）
    uint8 private _decimals;
    // 当前价格（int256，适配 Chainlink 的接口类型）
    int256 private _answer;

    // 构造函数：设置初始精度与价格
    // 参数示例：decimals_=8, answer_=3000*10^8 表示价格为 3000 美元，保留 8 位小数
    constructor(uint8 decimals_, int256 answer_) {
        _decimals = decimals_;
        _answer = answer_;
    }

    // 动态更新价格，用于在测试过程中变更市场价格场景
    function updateAnswer(int256 answer_) external {
        _answer = answer_;
    }

    // 返回当前精度
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    // 返回当前价格元组（简化实现）：
    // - roundId：固定为 0（占位）
    // - answer：当前价格
    // - startedAt：固定为 0（占位）
    // - updatedAt：使用当前区块时间，便于测试中断言是否有效更新
    // - answeredInRound：固定为 0（占位）
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (0, _answer, 0, block.timestamp, 0);
    }
}
