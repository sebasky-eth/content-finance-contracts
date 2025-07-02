// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

library GroupedTokenMapper {
    error InvalidGroupIdBitWidth(uint256 groupIdBitWidth, uint256 minimum, uint256 maximum);
    error GroupIdCannotBeZero();
    error GroupIdTooBig(uint256 groupId, uint256 maximumGroupId);

    function verifyGroupMetadata(uint256 groupIdBitWidth, uint256 groupId) internal pure {
        require(groupId != 0, GroupIdCannotBeZero());
        require(groupIdBitWidth >= 3 && groupIdBitWidth <= 253, InvalidGroupIdBitWidth(groupIdBitWidth, 3, 253));
        require((groupId >> groupIdBitWidth) == 0, GroupIdTooBig(groupId, (1 << groupIdBitWidth) - 1));
    }

    /// @notice Grouped created from: [tokenId][groupId]
    function mapTokenToGrouped(uint256 groupIdBitWidth, uint256 groupId, uint256 tokenId)
        internal
        pure
        returns (uint256)
    {
        return tokenId << groupIdBitWidth | groupId;
    }

    /// @notice Check if tokenId is possible to exist in grouped.
    function checkTokenForMapping(uint256 tokenIdBitWidth, uint256 tokenId) internal pure returns (bool) {
        return (tokenId >> tokenIdBitWidth) == 0;
    }

    function maximumTokenForMapping(uint256 tokenIdBitWidth) internal pure returns (uint256) {
        unchecked {
            return (1 << tokenIdBitWidth) - 1;
        }
    }
}
