// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.30;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title Interface for tokens that belong to groups. Information is saved inside 'tokenId'.
 * @author Sebasky (https://github.com/sebasky-eth)
 */
interface IGroupedToken is IERC165 {
    /// @notice Must be emited when contract is created. Inform 'tokenId' structure.
    /// For example: (0, 128, 128, 128) -> [tokenId: 128][groupId: 128]
    /// (0, 32,  32, 32) -> [192 available bits][tokenId: 32][groupId: 32]
    event GroupMetadata(
        uint256 offsetInGroupId, uint256 bitWidthInGroupId, uint256 offsetInTokenId, uint256 bitWidthInTokenId
    );

    function groupOf(uint256 tokenId) external view returns (uint256 groupId, uint256 tokenIdInGroup);

    function tokenOf(uint256 groupId, uint256 tokenId) external view returns (uint256);

    function groupMetaData()
        external
        view
        returns (uint256 offsetInGroupId, uint256 bitWidthInGroupId, uint256 offsetInTokenId, uint256 bitWidthInTokenId);
}
