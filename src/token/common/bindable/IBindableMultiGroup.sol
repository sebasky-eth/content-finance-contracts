// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.30;

import {IBindableToken} from "./IBindableToken.sol";
import {IGroupedToken} from "../IGroupedToken.sol";
import {IBindablyBySubset} from "./IBindablyBySubset.sol";
import {IBinder} from "./IBinder.sol";

/**
 * @title Central IBindableToken where binders are mapped to tokens by 'groupId' belonging.
 * @author Sebasky (https://github.com/sebasky-eth)
 * @notice Bits of 'tokenId' represent its group
 * @dev Information about binders can be read from events:
 * 1. {IGroupedToken} GroupMetadata(offsetInGroupId, bitWidthInGroupId, offsetInTokenId, bitWidthInTokenId)
 * 2. {IBindableMultiGroup} BinderAdded(groupId, binder) or BindersAdded(groupId, binders)
 */
interface IBindableMultiGroup is IGroupedToken, IBindablyBySubset, IBinder {
    /// @notice Declaration of factory. Used with CREATE3 to predict binders.
    /// Salt: [groupId] - for groups with max one binder
    /// (128,128): [binderOfGroup][groupId]
    /// [keccak256(binder descriptor)] (for example collection name)
    /// etc.
    event BinderFactory(address factory);

    event BinderAdded(uint256 indexed groupId, IBindableToken binder);
    event BindersAdded(uint256 indexed groupId, IBindableToken[] binders);

    function bindersOfGroup(uint256 groupId) external view returns (IBindableToken[] memory binders);
}
