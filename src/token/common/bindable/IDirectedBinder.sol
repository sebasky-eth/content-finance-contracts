// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.30;

import {IBindableToken} from "./IBindableToken.sol";

/**
 * @title IBindableToken where every token can have only one active binder and every binder is dormant (unbinding results in burn or transfer to collection).
 * @author Sebasky (https://github.com/sebasky-eth)
 * @dev For IERC721, but multi-owned could use it as adapter (by inheritance).
 */
interface IDirectedBinder is IBindableToken {
    /**
     * @notice Unbinds token in this collection and binds 'tokenId' to 'newBinder'.
     * Reverts, if caller not own 'tokenId'.
     */
    function bindTo(IBindableToken newBinder, uint256 tokenId) external;

    function bindFrom(IBindableToken previousBinder, uint256 tokenId) external;
}
