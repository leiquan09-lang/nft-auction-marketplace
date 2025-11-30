// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract MergeSortedArray {
    // 合并两个升序数组，返回新的升序数组
    function merge(uint256[] memory a, uint256[] memory b) external pure returns (uint256[] memory) {
        uint256 na = a.length;
        uint256 nb = b.length;
        uint256[] memory out = new uint256[](na + nb);
        uint256 i = 0;
        uint256 j = 0;
        uint256 k = 0;
        while (i < na && j < nb) {
            if (a[i] <= b[j]) {
                out[k++] = a[i++];
            } else {
                out[k++] = b[j++];
            }
        }
        while (i < na) {
            out[k++] = a[i++];
        }
        while (j < nb) {
            out[k++] = b[j++];
        }
        return out;
    }

    // LeetCode 风格：将 b 合并到 a（a 长度为 m+n，后面预留空位），返回合并结果
    function mergeInto(
        uint256[] memory a,
        uint256 m,
        uint256[] memory b,
        uint256 n
    ) external pure returns (uint256[] memory) {
        require(a.length == m + n, "a length must be m + n");
        // 从后向前合并，避免覆盖未处理元素
        int256 ia = int256(m) - 1;
        int256 ib = int256(n) - 1;
        int256 k = int256(m + n) - 1;
        while (ib >= 0 && ia >= 0) {
            if (a[uint256(ia)] >= b[uint256(ib)]) {
                a[uint256(k)] = a[uint256(ia)];
                ia--;
            } else {
                a[uint256(k)] = b[uint256(ib)];
                ib--;
            }
            k--;
        }
        while (ib >= 0) {
            a[uint256(k)] = b[uint256(ib)];
            ib--;
            k--;
        }
        return a;
    }
}