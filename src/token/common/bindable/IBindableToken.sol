// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.30;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title Multicollectional tokens that share owners. Every token could have multiple collections ('binder'), but only these 'bound' to it can transfer.
 * @author Sebasky (https://github.com/sebasky-eth)
 * @notice Possible binding effects:
 * DormantBinder:
 *      + Mint - burn during unbinding.
 *      + Transfer to owner - transfer to collection during unbinding.
 * PassiveBinder (mirror transfer of binded):
 *      + Unlock (IERC5192) - lock during unbinding.
 *          Lock is used as signal for dapps that user cannot transfer this token.
 *          But token can be still transfered by activated binders.
 *          Its recommended to add extra information by tokenURI that token is locked
 *          And link to website that can bind it there or give information about on-chain mechanism for binding (I have a lot of ideas there)
 * @dev Every token could have diffirent binders and some not binders at all.
 * If token can have multiple bounds, every activated binder MUST mirror transfers.
 *
 * dApps usage:
 * 'bindersOf(tokenId)' gives list of all collections that owner of token can control.
 *
 * collection usage:
 * If only DormantBinders exist and every token has maximum one bound:
 *      use SoloBinder {IERC721SoloBinder} for every binder.
 * For collections that have PassiveBinders or can have activated multiple binders at once:
 *      use CentralBinder {IERC721CentralBinder} for main collection that has all tokens and Binder {IERC721Binder} for rest.
 * For paired binders use:
 *      {IERC721PairedBinder}-{IERC721PairedBinder}
 *      Many {IERC721PairedBinder} - One: {IERC721MultiPairedBinder}
 */
interface IBindableToken is IERC165 {
    /**
     * @notice Returns if the 'tokenId' can bind to 'binder'.
     * @dev Reverts if tokenId not exist (in cross-collectional system)
     */
    function isBinderOf(uint256 tokenId, IBindableToken binder) external view returns (bool);

    /**
     * @notice Returns collections that 'tokenId' could bound to (excluding this one).
     * @dev Reverts if tokenId not exist (in cross-collectional system)
     */
    function bindersOf(uint256 tokenId)
        external
        view
        returns (IBindableToken[] memory collections, uint256[] memory ids);

    /**
     * @notice Returns collections that every token could bound to.
     * @dev Reverts if tokenId not exist (in cross-collectional system)
     */
    function binders() external view returns (IBindableToken[] memory collections);
}
