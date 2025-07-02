// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.30;

import {IBindableToken} from "./IBindableToken.sol";
import {IBindableMultiGroup} from "./IBindableMultiGroup.sol";

/**
 * @title IBindableToken that has immutable 'groupId' which points to tokens it represents in: {IBindableMultiGroup}.
 * @author Sebasky (https://github.com/sebasky-eth)
 */
interface IBindableGroup is IBindableToken {
    /// @notice emitted during deployment. Points at core binder and what 'groupId' represent this collection in the core.
    event MultiGroupRegistered(IBindableMultiGroup indexed core, uint256 indexed groupIdInCore);

    function bindingCore() external view returns (IBindableMultiGroup);
    function collectionGroup() external view returns (uint256 groupId);
}
