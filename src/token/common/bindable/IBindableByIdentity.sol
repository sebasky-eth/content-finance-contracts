// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.30;

import {IBindableToken} from "./IBindableToken.sol";

/**
 * @title Cross-collectional tokens bindable by other binders with 'tokenId'.
 * @author Sebasky (https://github.com/sebasky-eth)
 * @dev Dedicated to IERC721, but multi-owned could use it as adapter (by inheritance).
 */
interface IBindableByIdentity is IBindableToken {
    /**
     * @notice Binds 'tokenId' to this collection by other binder.
     * Reverts if caller is not authorized binder or 'tokenId' cannot be bound for 'owner'.
     */
    function bindFor(address owner, uint256 tokenId) external;

    /**
     * @notice Unbinds 'tokenId' from this collection by other binder.
     * Reverts if caller is not authorized binder or 'tokenId' cannot be bound for 'owner'.
     */
    function unbindFor(address owner, uint256 tokenId) external;
}
