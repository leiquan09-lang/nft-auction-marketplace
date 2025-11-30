// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract ReverseString {

      // 将输入字符串按字节顺序反转并返回。
    // 注意：此实现按字节反转，对多字节 UTF-8 字符（如中文）可能导致字符破坏。
    function reverse(string memory s) external pure returns (string memory) {
        bytes memory b = bytes(s);
        uint256 i = 0;
        if (b.length == 0) return s;
        uint256 j = b.length - 1;
        while (i < j) {
            bytes1 tmp = b[i];
            b[i] = b[j];
            b[j] = tmp;
            i++;
            j--;
        }
        return string(b);
    }

    // 将罗马数字字符串转换为整数（假定输入为大写有效罗马数字）
    // 示例: "MCMXCIV" -> 1994
    function romanToInt(string memory s) external pure returns (uint256) {
        bytes memory b = bytes(s);
        int256 acc = 0;
        uint256 n = b.length;
        for (uint256 i = 0; i < n; i++) {
            int256 v = int256(_value(b[i]));
            if (i + 1 < n) {
                int256 vnext = int256(_value(b[i + 1]));
                if (v < vnext) {
                    acc -= v;
                    continue;
                }
            }
            acc += v;
        }
        require(acc >= 0, "invalid roman result");
        return uint256(acc);
    }

    // 新增：将整数转换为罗马数字（参考 LeetCode "Integer to Roman"）
    // 示例: 1994 -> "MCMXCIV"
    function intToRoman(uint256 num) external pure returns (string memory) {
        require(num > 0 && num <= 3999, "out of range (1-3999)");
        uint256[13] memory vals = [uint256(1000), 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
        string[13] memory syms = ["M","CM","D","CD","C","XC","L","XL","X","IX","V","IV","I"];
        bytes memory res = abi.encodePacked();
        for (uint256 i = 0; i < vals.length && num > 0; i++) {
            while (num >= vals[i]) {
                res = abi.encodePacked(res, syms[i]);
                num -= vals[i];
            }
        }
        return string(res);
    }

    function _value(bytes1 c) internal pure returns (uint256) {
        if (c == bytes1("I")) return 1;
        if (c == bytes1("V")) return 5;
        if (c == bytes1("X")) return 10;
        if (c == bytes1("L")) return 50;
        if (c == bytes1("C")) return 100;
        if (c == bytes1("D")) return 500;
        if (c == bytes1("M")) return 1000;
        return 0;




       }    
}


    

