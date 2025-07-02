// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.30;

import {IBindableToken} from "./IBindableToken.sol";

/**
 * @title IBindableToken with external binding access.
 * @author Sebasky (https://github.com/sebasky-eth)
 * @dev Dedicated to IERC721, but multi-owned could use it as adapter (by inheritance).
 */
interface IBinder is IBindableToken {
    /**
     * @notice Binds 'tokenId' to this collection.
     * Reverts, if caller not own 'tokenId'.
     */
    function bind(uint256 tokenId) external;

    /**
     * @notice Unbinds 'tokenId' from this collection.
     * Reverts, if caller not own 'tokenId' or there are no other collections that token can bind to.
     */
    function unbind(uint256 tokenId) external;
}
