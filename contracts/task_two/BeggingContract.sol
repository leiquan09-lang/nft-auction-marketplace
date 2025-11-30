// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title BeggingContract - 一个简单的讨饭合约
/// @notice 允许用户捐赠 ETH，并记录捐赠信息，所有者可以提取资金
/// @dev 实现了基本的捐赠、记录和提款功能
contract BeggingContract is Ownable {
    /// @notice 记录每个地址的捐赠总额
    mapping(address => uint256) private _donations;

    /// @notice 捐赠事件，当收到捐款时触发
    /// @param donor 捐赠者地址
    /// @param amount 捐赠金额
    event Donation(address indexed donor, uint256 amount);

    /// @notice 提款事件，当所有者提款时触发
    /// @param owner 提款的所有者地址
    /// @param amount 提款金额
    event Withdrawal(address indexed owner, uint256 amount);

    /// @notice 构造函数，初始化合约所有者
    /// @param initialOwner 合约初始所有者
    constructor(address initialOwner) Ownable(initialOwner) {}

    /// @notice 捐赠函数，接收 ETH 并记录
    /// @dev 使用 payable 修饰符接收 ETH
    function donate() external payable {
        require(msg.value > 0, unicode"捐赠金额必须大于 0");
        
        _donations[msg.sender] += msg.value;
        emit Donation(msg.sender, msg.value);
    }

    /// @notice 提取合约内所有资金
    /// @dev 仅限合约所有者调用，使用 call 方法发送 ETH 以避免 Gas 限制问题
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, unicode"无可提取资金");

        (bool success, ) = owner().call{value: balance}("");
        require(success, "Transfer failed");

        emit Withdrawal(owner(), balance);
    }

    /// @notice 查询指定地址的捐赠金额
    /// @param donor 要查询的捐赠者地址
    /// @return 该地址累计捐赠的金额
    function getDonation(address donor) external view returns (uint256) {
        return _donations[donor];
    }

    /// @notice 获取合约当前余额
    /// @return 合约内的 ETH 余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
