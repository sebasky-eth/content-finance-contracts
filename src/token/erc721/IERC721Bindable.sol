// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.30;

import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IBindableToken} from "../common/bindable/IBindableToken.sol";

/**
 * @title IERC721 extension that give tokens cross-collectional ability.
 * @author Sebasky (https://github.com/sebasky-eth)
 * @notice Binding to collection: token transfer become active there.
 * Unbinding from collection: token transfer become inactive there.
 */
interface IERC721Bindable is IBindableToken, IERC721 {
    /**
     * @notice Returns multi-collectional owner of 'tokenId'.
     * Reverts, if token not exist in any collection.
     * @dev Could be gas pricy.
     */
    function effectiveOwnerOf(uint256 tokenId) external view returns (address);

    /**
     * @notice Returns if this collection is bound to 'tokenId'.
     */
    function isBound(uint256 tokenId) external view returns (bool);
}
