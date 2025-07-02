// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0

pragma solidity ^0.8.30;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

import {IERC721MultipairedBinder} from "../IERC721MultipairedBinder.sol";
import {IERC721PairedBinder, IERC721Bindable} from "../IERC721PairedBinder.sol";
import {IBindableToken} from "../../common/bindable/IBindableToken.sol";
import {IGroupedToken} from "../../common/IGroupedToken.sol";
import {IBindableMultiGroup} from "../../common/bindable/IBindableMultiGroup.sol";
import {GroupedTokenMapper} from "../../utils/GroupedTokenMapper.sol";

/**
 * @title ERC721 extension (for OpenZeppelin base) for two-collectional tokens. Smaller one. Released before.
 * @dev SHOULD BE deployed with CREATE3
 * @author Sebasky (https://github.com/sebasky-eth)
 * @notice Bigger one is: {IERC721MultipairedBinder}
 * Cross-collectional switch from there by: burning-minting.
 * Switch in core by: lock-unlock.
 * Core collection always mirror transfers (if deployed).
 * Only one collection can be activated for token (in this collection).
 * Cannot have burning outside binding mechanism (but core collection can have burning).
 * Unbinding (burning) called by core collection is blocked before any owner for specific token in this collection does unbinding.
 */
abstract contract ERC721PairedBinderPrelaunched is ERC721, IERC721PairedBinder {
    error CoreBinderRequired();

    error CrossCollectionalControlNotAllowed(uint256 tokenId);
    error UnauthorizedCaller(address caller);
    error TokenNotUnbound(uint256 tokenId);
    error TokenNotBoundFor(address owner, uint256 tokenId);

    IERC721MultipairedBinder internal immutable _coreBinder;
    uint256 internal immutable _groupId;
    uint256 internal immutable _groupIdBitWidth;
    uint256 internal immutable _tokenIdBitWidth;

    mapping(uint256 tokenId => bool) private _wasUnboundAtLeastOnce;

    /**
     * @param coreBinder - main collection that always display proper owner. Could be not deployed yet (CREATE3).
     * @param groupId - unique groupId of this collection. Used to map 'tokenId' to IERC721MultipairedBinder's 'tokenId'.
     * @param groupIdBitWidth - total bits used to store 'groupId' inside 'tokenId' in IERC721MultipairedBinder. Must be same for every PairedBinder.
     */
    constructor(IERC721MultipairedBinder coreBinder, uint256 groupId, uint256 groupIdBitWidth) {
        require(address(coreBinder) != address(0), CoreBinderRequired());
        GroupedTokenMapper.verifyGroupMetadata(groupIdBitWidth, groupId);

        _coreBinder = coreBinder;
        _groupId = groupId;
        _groupIdBitWidth = groupIdBitWidth;
        unchecked {
            _tokenIdBitWidth = 256 - groupIdBitWidth;
        }

        emit MultiGroupRegistered(coreBinder, groupId);
    }

    /*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
            ERC165 Overrides
    -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC721PairedBinder).interfaceId || interfaceId == type(IERC721Bindable).interfaceId
            || interfaceId == type(IBindableToken).interfaceId || super.supportsInterface(interfaceId);
    }

    /*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
            ERC721 Overrides
    -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/

    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
        if (to == address(_coreBinder)) {
            _unbind(tokenId, _msgSender());
        } else if (to == address(this)) {
            _bind(tokenId, _msgSender());
        } else {
            super.transferFrom(from, to, tokenId);
            _propagateTransfer(from, to, tokenId);
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        virtual
        override(ERC721, IERC721)
    {
        if (to == address(_coreBinder)) {
            _unbind(tokenId, _msgSender());
        } else {
            super.safeTransferFrom(from, to, tokenId, data);
            _propagateTransfer(from, to, tokenId);
        }
    }

    function _propagateTransfer(address from, address to, uint256 tokenId) internal virtual {
        (bool success,) = address(_coreBinder).call(
            abi.encodeWithSelector(IERC721MultipairedBinder.mirroredTransferFrom.selector, from, to, tokenId, _groupId)
        );
    }

    /*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
            IBindableToken
    -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/

    /**
     * @notice Returns if the 'tokenId' can bind to 'binder'.
     * @dev Does not revert
     */
    function isBinderOf(uint256 tokenId, IBindableToken binder) external view virtual returns (bool) {
        bool isCoreDeployed = _requireExist(tokenId);
        return address(binder) == address(this) || (isCoreDeployed && address(binder) == address(_coreBinder));
    }

    /**
     * @notice Returns collections that 'tokenId' could bound to (excluding this one).
     */
    function bindersOf(uint256 tokenId)
        external
        view
        virtual
        returns (IBindableToken[] memory collections, uint256[] memory ids)
    {
        bool isCoreDeployed = _requireExist(tokenId);
        if (isCoreDeployed) {
            collections = new IBindableToken[](1);
            ids = new uint256[](1);
            collections[0] = _coreBinder;
            ids[0] = GroupedTokenMapper.mapTokenToGrouped(_groupIdBitWidth, _groupId, tokenId);
        }
        //Empty otherwise
    }

    /**
     * @notice Returns collections that every token could bound to.
     */
    function binders() external view virtual returns (IBindableToken[] memory collections) {
        if (_isCoreBinderDeployed()) {
            collections = new IBindableToken[](1);
            collections[0] = _coreBinder;
        }
        //Empty otherwise
    }

    function _requireExist(uint256 tokenId) internal view virtual returns (bool isCoreDeployed) {
        address core = address(_coreBinder);
        address owner = _ownerOf(tokenId);
        if (owner != address(0)) {
            return core.code.length > 0;
        }

        (bool success, bytes memory data) =
            core.staticcall(abi.encodeWithSelector(IGroupedToken.tokenOf.selector, _groupId, tokenId));
        if (success && data.length == 32) {
            return true;
        }
        revert ERC721NonexistentToken(tokenId);
    }

    /*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
            IERC721Bindable
    -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/

    /**
     * @notice Returns multi-collectional owner of 'tokenId'.
     * Reverts, if token not exist in any collection.
     */
    function effectiveOwnerOf(uint256 tokenId) external view virtual returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner != address(0)) {
            return owner;
        }

        (bool success, bytes memory data) = address(_coreBinder).staticcall(
            abi.encodeWithSelector(IERC721Bindable.effectiveOwnerOf.selector, _requiredMapTokenToGrouped(tokenId))
        );

        if (success && data.length == 32) {
            return abi.decode(data, (address));
        }
        revert ERC721NonexistentToken(tokenId);
    }

    /**
     * @notice Returns if this collection is bound to 'tokenId'.
     */
    function isBound(uint256 tokenId) external view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
            IBinder & IBindableByIdentity
    -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/

    function bind(uint256 tokenId) external virtual {
        address sender = _msgSender();

        _bind(tokenId, sender);
        _coreBinder.unbindFor(sender, tokenId, _groupId);
    }

    function bindFor(address owner, uint256 tokenId) external virtual {
        require(msg.sender == address(_coreBinder), UnauthorizedCaller(msg.sender));
        _bind(tokenId, owner);
    }

    function unbind(uint256 tokenId) external virtual {
        address sender = _msgSender();
        if (!_wasUnboundAtLeastOnce[tokenId]) {
            _wasUnboundAtLeastOnce[tokenId] = true;
        }
        _unbind(tokenId, sender);
        _coreBinder.bindFor(sender, tokenId, _groupId);
    }

    function unbindFor(address operator, uint256 tokenId) external virtual {
        require(msg.sender == address(_coreBinder), UnauthorizedCaller(msg.sender));
        require(_wasUnboundAtLeastOnce[tokenId], CrossCollectionalControlNotAllowed(tokenId));

        _unbind(tokenId, operator);
    }

    function _bind(uint256 tokenId, address operator) internal virtual {
        //  token never unbound (including: core binder not deployed yet)
        require(_wasUnboundAtLeastOnce[tokenId], CrossCollectionalControlNotAllowed(tokenId));

        address prevOwner = _update(operator, tokenId, address(0));
        require(prevOwner == address(0), TokenNotUnbound(tokenId));
        //Assume that this collection hasn't other burning mechanic.
    }

    function _unbind(uint256 tokenId, address operator) internal virtual {
        address prevOwner = _update(address(0), tokenId, address(0));
        require(prevOwner != address(0), ERC721NonexistentToken(tokenId));
        require(prevOwner == operator, TokenNotBoundFor(prevOwner, tokenId));
    }

    /*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
            IBindableGroup
    -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/

    function bindingCore() external view virtual returns (IBindableMultiGroup) {
        return _coreBinder;
    }

    function collectionGroup() external view virtual returns (uint256 groupId) {
        return _groupId;
    }

    /*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
            Extra
    -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/

    function wasUnboundAtLeastOnce(uint256 tokenId) external view virtual returns (bool) {
        return _wasUnboundAtLeastOnce[tokenId];
    }

    /*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
            Common internals
    -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/

    function _isCoreBinderDeployed() internal view virtual returns (bool) {
        return address(_coreBinder).code.length > 0;
    }

    function _requiredMapTokenToGrouped(uint256 tokenId) internal view virtual returns (uint256) {
        require(GroupedTokenMapper.checkTokenForMapping(_tokenIdBitWidth, tokenId), ERC721NonexistentToken(tokenId));
        return GroupedTokenMapper.mapTokenToGrouped(_groupIdBitWidth, _groupId, tokenId);
    }
}
