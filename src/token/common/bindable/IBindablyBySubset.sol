// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.30;

import {IBindableToken} from "./IBindableToken.sol";

/**
 * @title Cross-collectional tokens bindable by 'tokenId' and 'groupId'.
 * @author Sebasky (https://github.com/sebasky-eth)
 * @notice Caller to IBindablyBySubset declare his 'groupId' and pass its 'tokenId' so IBindablyBySubset can match it to right token.
 * @dev Dedicated to IERC721, but multi-owned could use it as adapter (by inheritance).
 */
interface IBindablyBySubset is IBindableToken {
    /**
     * @notice Binds 'tokenId' of 'groupId' to this collection by other binder.
     * Reverts if caller is not authorized binder or 'tokenId' in 'groupId' cannot be bound for 'owner'.
     */
    function bindFor(address owner, uint256 tokenId, uint256 groupId) external;

    /**
     * @notice Unbinds 'tokenId' of 'groupId' from this collection by other binder.
     * Reverts if caller is not authorized binder or 'tokenId' in 'groupId' cannot be bound for 'owner'.
     */
    function unbindFor(address owner, uint256 tokenId, uint256 groupId) external;
}
