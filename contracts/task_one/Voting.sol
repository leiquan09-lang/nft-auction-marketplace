// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28; // 指定Solidity编译器版本要求

contract Voting { // 定义投票合约
    mapping(bytes32 => uint256) private _votes; // 存储每个候选人的票数，key为候选人标识（bytes32）
    mapping(bytes32 => bool) private _candidateExists; // 记录候选人是否已被添加，避免重复加入列表
    bytes32[] private _candidates; // 保存所有已出现候选人的数组，用于遍历或重置票数

    event Voted(bytes32 candidate, uint256 total); // 当有人投票时触发，包含候选人和当前总票数
    event Reset(); // 当所有票数被重置时触发

    function vote(bytes32 candidate) external { // 外部可调用的投票函数，传入候选人标识
        if (!_candidateExists[candidate]) { // 如果候选人还未被记录
            _candidateExists[candidate] = true; // 标记候选人为已存在
            _candidates.push(candidate); // 将候选人加入候选人数组
        }
        _votes[candidate] += 1; // 候选人的票数加一
        emit Voted(candidate, _votes[candidate]); // 触发Voted事件，通知链上外部监听者
    }

    function getVotes(bytes32 candidate) external view returns (uint256) { // 查询指定候选人的票数（只读）
        return _votes[candidate]; // 返回映射中该候选人的票数（若不存在，则为0）
    }

    function resetVotes() external { // 重置所有候选人的票数为0（外部可调用）
        for (uint256 i = 0; i < _candidates.length; i++) { // 遍历候选人数组
            _votes[_candidates[i]] = 0; // 将每个候选人的票数设为0
        }
        emit Reset(); // 触发Reset事件，表示已完成重置
    }
}

