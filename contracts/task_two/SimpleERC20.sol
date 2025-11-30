// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title SimpleERC20
/// @notice 参考 OpenZeppelin 的 IERC20 接口实现的简易 ERC20 代币
/// @dev 提供标准的余额查询、授权、转账与代扣转账；另外提供仅所有者可调用的增发函数
contract SimpleERC20 is IERC20 {
    /// @notice 代币名称（例如：MyToken）
    string public name;
    /// @notice 代币符号（例如：MTK）
    string public symbol;
    /// @notice 代币精度（标准 ERC20 约定为 18）
    uint8 public constant decimals = 18;
    /// @inheritdoc IERC20
    uint256 public override totalSupply;
    /// @notice 合约所有者地址（构造时设置为部署者）
    address public owner;

    /// @dev 账户余额表：account => balance
    mapping(address => uint256) private _balances;
    /// @dev 授权额度表：owner => spender => allowance
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @dev 仅允许所有者执行的修饰器
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    /// @param _name 代币名称
    /// @param _symbol 代币符号
    constructor(string memory _name, string memory _symbol) {
        // 初始化元数据与所有者
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /// @inheritdoc IERC20
    function allowance(address _owner, address spender) public view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 amount) public override returns (bool) {
        // 基本校验：禁止转账到零地址，余额必须充足
        address from = msg.sender;
        require(to != address(0), "to zero");
        require(_balances[from] >= amount, "insufficient");
        // 余额更新（使用 unchecked 避免不必要的溢出检查）
        unchecked {
            _balances[from] -= amount;
            _balances[to] += amount;
        }
        // 触发标准事件，便于前端与区块浏览器索引
        emit Transfer(from, to, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 amount) public override returns (bool) {
        // 设置授权额度并记录事件
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        // 校验授权额度、余额与目标地址有效性
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(to != address(0), "to zero");
        require(_balances[from] >= amount, "insufficient");
        require(currentAllowance >= amount, "no allowance");
        // 扣减授权、变更余额并记录事件
        unchecked {
            _allowances[from][msg.sender] = currentAllowance - amount;
            _balances[from] -= amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice 增发代币到指定地址，仅所有者可调用
    /// @param to 接收增发代币的地址（不可为零地址）
    /// @param amount 增发数量（按 18 位精度计）
    /// @dev 按标准事件语义，铸造行为以 from=address(0) 的 Transfer 事件表示
    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "to zero");
        totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}
