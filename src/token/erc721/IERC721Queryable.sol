// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.30;

interface IERC721Queryable {
    function tokensOfOwner(address owner) external view returns (uint256[] memory);

    function tokensOfOwnerIn(address owner, uint256 start, uint256 stop) external view returns (uint256[] memory);
}
