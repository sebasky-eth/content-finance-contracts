// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

library ArrayCreator {
    function createStrings(uint256 len, string memory value) internal pure returns (string[] memory arr) {
        arr = new string[](len);
        for (uint256 i = 0; i < len; i++) {
            arr[i] = value;
        }
        return arr;
    }
}
