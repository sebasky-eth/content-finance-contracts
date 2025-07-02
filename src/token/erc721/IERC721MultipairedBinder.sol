// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.30;

import {IBindableMultiGroup} from "../common/bindable/IBindableMultiGroup.sol";
import {IERC721CoreBinder} from "./IERC721CoreBinder.sol";
import {IERC721Mirrorable} from "./IERC721Mirrorable.sol";

/**
 * @title Core Binder for {IERC721PairedBinder} that mirror all tokens and control inter-collectional binding mechanism {see IBindableToken}.
 * @author Sebasky (https://github.com/sebasky-eth)
 * @notice Unbinding in one, result in binding in other (because they exist in pairs).
 */
interface IERC721MultipairedBinder is IERC721CoreBinder, IBindableMultiGroup, IERC721Mirrorable {
    /**
     * @notice Mirror transfer.
     * Reverts if called by non-authorized for 'groupId' binder.
     * @dev Verification of binders: CREATE3.predictDeterministicAddress(groupId, factoryAddress)
     */
    function mirroredTransferFrom(address from, address to, uint256 tokenId, uint256 groupId) external;
}
