// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract BinarySearch {
    // 在已升序排序的 uint256 数组中查找目标值
    // 返回找到时的索引（int256），找不到返回 -1

    // 新增：内部实现，供合约内部和外部封装复用
    function _binarySearch(uint256[] memory arr, uint256 target) internal pure returns (int256) {
        int256 low = 0;
        int256 high = int256(arr.length) - 1;
        while (low <= high) {
            int256 mid = low + (high - low) / 2;
            uint256 v = arr[uint256(mid)];
            if (v == target) {
                return mid;
            } else if (v < target) {
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }
        return -1;
    }

    // 对外接口保持 external（或可改为 public），调用内部实现
    function binarySearch(uint256[] memory arr, uint256 target) external pure returns (int256) {
        return _binarySearch(arr, target);
    }

    // 可选：返回 (found, index)，更符合 Solidity 无负数索引的习惯
    function binarySearchWithFlag(uint256[] memory arr, uint256 target) external pure returns (bool, uint256) {
        int256 idx = _binarySearch(arr, target);
        if (idx < 0) return (false, 0);
        return (true, uint256(idx));
    }
}