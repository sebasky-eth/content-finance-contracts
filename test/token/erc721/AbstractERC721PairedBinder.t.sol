// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";

import {CREATE3} from "solady/utils/CREATE3.sol";

import {IERC721PairedBinder} from "../../../../src/token/erc721/IERC721PairedBinder.sol";
import {IERC721MultipairedBinder} from "../../../../src/token/erc721/IERC721MultipairedBinder.sol";
import {IBindableToken} from "../../../../src/token/common/bindable/IBindableToken.sol";

import {IncrementalNftTest} from "../../common/IncrementalNftTest.t.sol";

/**
 * @notice Contracts and their usage:
 * {AbstractTestERC721PairedBinder} - shared functions.
 * {AbstractTestERC721PairedBinderWithCore} - shared functions with core released
 *
 * Tests based on core ({IERC721MultipairedBinder}):
 * {AbstractTestERC721PairedBinderCoreAgnostic} - Test that are not dependent on core.
 * {AbstractTestERC721PairedBinderPrereleased} - For PairedBinder that was released before core.
 * {AbstractTestERC721PariedBinderReleased} - For PairedBinder and safe mockup of core.
 * {AbstractTestERC721PairedBinderBuggedCore} - For PairedBinder and core that try to act againts contract and token owners.
 */
abstract contract AbstractTestERC721PairedBinder is IncrementalNftTest {
    uint256 internal _groupId = 1;
    uint256 internal _groupIdBitWidth = 32;

    uint256 private _previousGroupId = _groupId;
    uint256 private _previousGroupIdBitWidth = _groupIdBitWidth;

    function _coreAddress() internal virtual returns (address);

    function _createMintedFor(address minter, uint256 tokenId) internal virtual returns (IERC721PairedBinder);

    /// @notice Return collection without any minted tokens.
    function _createPairedBinder() internal virtual returns (IERC721PairedBinder);

    function _minimumGroupIdBitWidth() internal view virtual returns (uint256) {
        return 16;
    }

    function _maximumGroupIdBitWidth() internal view virtual returns (uint256) {
        return 256 - 16;
    }

    function resetGroupId() internal {
        _groupId = _previousGroupId;
    }

    function resetGroupIdBitWidth() internal {
        _groupIdBitWidth = _previousGroupIdBitWidth;
    }

    function changeGroupId(uint256 groupId) internal {
        _previousGroupId = _groupId;
        _groupId = groupId;
    }

    function changeGroupIdBitWidth(uint256 groupIdBitWidth) internal {
        _previousGroupIdBitWidth = _groupIdBitWidth;
        _groupIdBitWidth = groupIdBitWidth;
    }

    function changeGroupMetadata(uint256 groupId, uint256 groupIdBitWidth) internal {
        changeGroupId(groupId);
        changeGroupIdBitWidth(groupIdBitWidth);
    }

    function resetGroupMetadata() internal {
        resetGroupId();
        resetGroupIdBitWidth();
    }

    function _tokenIdBitWidth() internal view returns (uint256) {
        return 256 - _groupIdBitWidth;
    }

    function assumedCreateMintedFor(address minter, uint256 tokenId)
        internal
        virtual
        returns (IERC721PairedBinder, uint256 boundTokenId)
    {
        tokenId = boundMintFor(minter, tokenId);
        return (_createMintedFor(minter, tokenId), tokenId);
    }

    function assumedCreateTransferable(address from, address to, uint256 tokenId)
        internal
        returns (IERC721PairedBinder, uint256)
    {
        assumeTrasferTarget(from, to);
        vm.assume(to != _coreAddress());
        IERC721PairedBinder binder;
        (binder, tokenId) = assumedCreateMintedFor(from, tokenId);
        vm.assume(to != address(binder));
        return (binder, tokenId);
    }

    function assumedCreateUnminted(uint256 lastMinted, uint256 tokenId)
        internal
        returns (IERC721PairedBinder, uint256, uint256)
    {
        (lastMinted, tokenId) = boundUnminted(lastMinted, tokenId);
        IERC721PairedBinder binder = _createMintedFor(EOA, lastMinted);
        return (binder, lastMinted, tokenId);
    }

    function test_AbstractTestERC721PairedBinderShared_constants() public view {
        uint256 tokenIdBitWidth = 256 - _maximumGroupIdBitWidth();
        vm.assume((_maxTokenId() >> tokenIdBitWidth) == 0);
    }

    function testFuzz_AbstractTestERC721PairedBinderSharedassumedCreateMintedFor(address owner, uint256 tokenId)
        public
    {
        assumedCreateMintedFor(owner, tokenId);
    }

    function test_AbstractTestERC721PairedBinderShared_createPairedBinder() public {
        _createPairedBinder();
    }

    /// @notice Test also 'bindingCore()'
    function test_AbstractTestERC721PairedBinderShared_coreAddress() public {
        IERC721PairedBinder binder = _createPairedBinder();
        address bindingCore = address(binder.bindingCore());
        vm.assertEq(bindingCore, _coreAddress());
    }

    function test_bindersOf_neverMintedToken(uint256 lastMinted, uint256 tokenId) public {
        IERC721PairedBinder binder;
        (binder, lastMinted, tokenId) = assumedCreateUnminted(lastMinted, tokenId);
        vm.expectRevert();
        binder.bindersOf(tokenId);
    }

    function test_isBinderOf_neverMintedToken(uint256 lastMinted, uint256 tokenId) public {
        IERC721PairedBinder binder;
        (binder, lastMinted, tokenId) = assumedCreateUnminted(lastMinted, tokenId);
        vm.expectRevert();
        binder.isBinderOf(tokenId, IBindableToken(address(this)));
    }
}

abstract contract AbstractTestERC721PairedBinderCoreAgnostic is AbstractTestERC721PairedBinder {
    function testFuzz_transfer(address from, address to, uint256 tokenId) public {
        IERC721PairedBinder col;
        (col, tokenId) = assumedCreateTransferable(from, to, tokenId);

        vm.prank(from);
        col.transferFrom(from, to, tokenId);
        address owner = col.ownerOf(tokenId);
        vm.assertEq(owner, to);
    }

    function testFuzz_safeTransfer(address from, address to, uint256 tokenId) public {
        IERC721PairedBinder col;
        (col, tokenId) = assumedCreateTransferable(from, to, tokenId);

        vm.prank(from);
        col.safeTransferFrom(from, to, tokenId);
        address owner = col.ownerOf(tokenId);
        vm.assertEq(owner, to);
    }

    function testFuzz_transfer_unauthorized(address from, address to, address unauthorizedCaller, uint256 tokenId)
        public
    {
        IERC721PairedBinder col;
        (col, tokenId) = assumedCreateTransferable(from, to, tokenId);

        vm.prank(unauthorizedCaller);

        vm.expectRevert();
        col.transferFrom(from, to, 0);
    }

    function testFuzz_safeTransfer_unauthorized(address from, address to, address unauthorizedCaller, uint256 tokenId)
        public
    {
        IERC721PairedBinder col;
        (col, tokenId) = assumedCreateTransferable(from, to, tokenId);

        vm.startPrank(unauthorizedCaller);

        vm.expectRevert();
        col.safeTransferFrom(from, to, 0);
    }

    function testFuzz_effectiveOwnerOf(uint256 tokenId, address owner) public {
        IERC721PairedBinder col;
        (col, tokenId) = assumedCreateMintedFor(owner, tokenId);
        vm.assertEq(col.ownerOf(tokenId), owner);
    }

    function testFuzz_ownerOf(uint256 tokenId, address owner) public {
        IERC721PairedBinder col;
        (col, tokenId) = assumedCreateMintedFor(owner, tokenId);
        vm.assertEq(col.effectiveOwnerOf(tokenId), owner);
    }

    function testFuzz_isBound_noBinding(uint256 maximumTokenId, address owner) public {
        IERC721PairedBinder col;
        (col, maximumTokenId) = assumedCreateMintedFor(owner, maximumTokenId);
        for (uint256 i; i <= maximumTokenId; i++) {
            vm.assertEq(col.isBound(i), true);
        }
    }
}

/**
 * @title Tests for IERC721PairedBinder that is deployed before main collection
 * @author
 */
abstract contract AbstractTestERC721PairedBinderPrereleased is AbstractTestERC721PairedBinder {
    /// @notice Cannot use bind before core was deployed
    function testFuzz_bind(address owner, uint256 tokenId) public {
        IERC721PairedBinder binder;
        (binder, tokenId) = assumedCreateMintedFor(owner, tokenId);

        vm.prank(owner);
        vm.expectRevert();
        binder.bind(tokenId);
    }

    /// @notice Cannot use unbind before core was deployed.
    function testFuzz_unbind(address owner, uint256 tokenId) public {
        IERC721PairedBinder binder;
        (binder, tokenId) = assumedCreateMintedFor(owner, tokenId);

        vm.prank(owner);
        vm.expectRevert();
        binder.unbind(tokenId);
    }

    /// @notice Cannot use bindFor before core was deployed.
    function testFuzz_bindFor(address owner, uint256 tokenId, address caller) public {
        IERC721PairedBinder binder;
        (binder, tokenId) = assumedCreateMintedFor(owner, tokenId);
        vm.assume(caller != _coreAddress());

        vm.prank(caller);
        vm.expectRevert();
        binder.bindFor(owner, tokenId);
    }

    /// @notice Cannot use unbindFor before core was deployed.
    function testFuzz_unbindFor(address owner, uint256 tokenId, address caller) public {
        IERC721PairedBinder binder;
        (binder, tokenId) = assumedCreateMintedFor(owner, tokenId);
        vm.assume(caller != _coreAddress());

        vm.prank(caller);
        vm.expectRevert();
        binder.unbindFor(owner, tokenId);
    }

    function testFuzz_bindersOf_empty(address owner, uint256 tokenId) public {
        IERC721PairedBinder binder;
        (binder, tokenId) = assumedCreateMintedFor(owner, tokenId);

        (IBindableToken[] memory collections, uint256[] memory ids) = binder.bindersOf(tokenId);
        bool isCollectionEmpty = collections.length == 0;
        bool isIdsEmpty = ids.length == 0;
        vm.assertTrue(isCollectionEmpty);
        vm.assertTrue(isIdsEmpty);
    }

    function test_binders_empty() public {
        IERC721PairedBinder binder = _createPairedBinder();
        IBindableToken[] memory collections = binder.binders();
        bool isCollectionsEmpty = collections.length == 0;
        vm.assertTrue(isCollectionsEmpty);
    }
}

abstract contract AbstractTestERC721PairedBinderWithCore is AbstractTestERC721PairedBinder {
    function _createCoreMintedFor(address minter, uint256 tokenId)
        internal
        virtual
        returns (IERC721MultipairedBinder);

    function assumedCreateCore(address minter, uint256 tokenId)
        internal
        virtual
        returns (IERC721MultipairedBinder, uint256)
    {
        tokenId = boundMintFor(minter, tokenId);
        return (_createCoreMintedFor(minter, tokenId), tokenId);
    }

    function assumedCreateDuo(address minter, uint256 tokenId)
        internal
        virtual
        returns (IERC721PairedBinder binder, IERC721MultipairedBinder core, uint256 boundedTokenId)
    {
        (binder, boundedTokenId) = assumedCreateMintedFor(minter, tokenId);
        core = _createCoreMintedFor(minter, boundedTokenId);
    }

    function assumeGroup(uint256 groupId, uint256 groupBitWidth) internal view returns (uint256) {
        groupBitWidth = bound(groupBitWidth, _minimumGroupIdBitWidth(), _maximumGroupIdBitWidth());
        vm.assume(groupId > 0);
        vm.assume((groupId >> groupBitWidth) == 0);
        return groupBitWidth;
    }

    function assumedCreateDuo(address minter, uint256 tokenId, uint256 groupId, uint256 groupIdBitWidth)
        internal
        virtual
        returns (IERC721PairedBinder binder, IERC721MultipairedBinder core, uint256 boundTokenId)
    {
        changeGroupMetadata(groupId, groupIdBitWidth);
        (binder, core, boundTokenId) = assumedCreateDuo(minter, tokenId);
        resetGroupMetadata();
    }

    function assumedCreateDuoTransfer(address from, address to, uint256 tokenId)
        internal
        virtual
        returns (IERC721PairedBinder binder, IERC721MultipairedBinder core, uint256 boundTokenId)
    {
        assumeTrasferTarget(from, to);
        (binder, core, boundTokenId) = assumedCreateDuo(from, tokenId);
        vm.assume(to != address(binder) && to != address(core));
    }

    function createDuoUnminted(uint256 lastMinted, uint256 tokenId)
        internal
        virtual
        returns (IERC721PairedBinder binder, IERC721MultipairedBinder core, uint256 boundTokenId)
    {
        (lastMinted, boundTokenId) = boundUnminted(lastMinted, tokenId);
        binder = _createMintedFor(EOA, lastMinted);
        core = _createCoreMintedFor(EOA, lastMinted);
    }

    function testFuzz_AbstractTestERC721PairedBinderWithCore_createCoreMintedFor(address owner, uint256 tokenId)
        public
    {
        IERC721MultipairedBinder core;
        (core, tokenId) = assumedCreateCore(owner, tokenId);
        vm.assertEq(address(core), _coreAddress());
    }

    /// @notice Secure supply: Core cannot add tokens to collection that was never minted.
    /// @dev If token was never unbinded, bindFor must revert.
    function testFuzz_bindFor_neverMintedToken(uint256 lastMinted, uint256 tokenId, address passedOwner) public {
        IERC721PairedBinder binder;
        (binder, lastMinted, tokenId) = assumedCreateUnminted(lastMinted, tokenId);
        _createCoreMintedFor(EOA, lastMinted);

        vm.prank(_coreAddress());
        vm.expectRevert();
        binder.bindFor(passedOwner, tokenId);
    }

    function testFuzz_unbindFor_NonExistentToken(uint256 lastMinted, uint256 tokenId, address passedOwner) public {
        IERC721PairedBinder binder;
        (binder, lastMinted, tokenId) = assumedCreateUnminted(lastMinted, tokenId);
        _createCoreMintedFor(EOA, lastMinted);

        vm.prank(_coreAddress());
        vm.expectRevert();
        binder.unbindFor(passedOwner, tokenId);
    }

    function testFuzz_bind_neverMintedToken(uint256 lastMinted, uint256 tokenId, address caller) public {
        IERC721PairedBinder binder;
        (binder, lastMinted, tokenId) = assumedCreateUnminted(lastMinted, tokenId);
        _createCoreMintedFor(EOA, lastMinted);

        vm.prank(caller);
        vm.expectRevert();
        binder.bind(tokenId);
    }

    function testFuzz_unbind_NonExistentToken(uint256 lastMinted, uint256 tokenId, address caller) public {
        IERC721PairedBinder binder;
        (binder, lastMinted, tokenId) = assumedCreateUnminted(lastMinted, tokenId);
        _createCoreMintedFor(EOA, lastMinted);

        vm.prank(caller);
        vm.expectRevert();
        binder.unbind(tokenId);
    }

    function testFuzz_isBinderOf_invalid(address owner, uint256 tokenId, address checkedBinder) public {
        vm.assume(checkedBinder != _coreAddress());
        IERC721PairedBinder collection;
        (collection, tokenId) = assumedCreateMintedFor(owner, tokenId);
        _createCoreMintedFor(owner, tokenId);

        bool isBinder = collection.isBinderOf(tokenId, IERC721MultipairedBinder(checkedBinder));
        vm.assertTrue(!isBinder);
    }

    function testFuzz_isBinderOf_core(address owner, uint256 tokenId) public {
        IERC721PairedBinder binder;
        (binder, tokenId) = assumedCreateMintedFor(owner, tokenId);
        _createCoreMintedFor(owner, tokenId);

        bool isBinder = binder.isBinderOf(tokenId, IERC721MultipairedBinder(_coreAddress()));
        vm.assertTrue(isBinder);
    }

    function testFuzz_effectiveOwnerOf_bindedToken(address owner, uint256 tokenId) public {
        IERC721PairedBinder binder;
        (binder, tokenId) = assumedCreateMintedFor(owner, tokenId);
        _createCoreMintedFor(owner, tokenId);

        address effectiveOwner = binder.effectiveOwnerOf(tokenId);
        vm.assertEq(effectiveOwner, owner);
    }
}

abstract contract AbstractTestERC721PairedBinderBuggedCore is AbstractTestERC721PairedBinderWithCore {
    /// @notice Prereleased collection should not allow to unbind token from core that was never unbound from collection.
    function testFuzz_unbindFor_neverUnboundToken(address owner, uint256 tokenId) public {
        IERC721PairedBinder binder;
        (binder, tokenId) = assumedCreateMintedFor(owner, tokenId);
        _createCoreMintedFor(owner, tokenId);

        vm.prank(_coreAddress());
        vm.expectRevert();
        binder.unbindFor(owner, tokenId);
    }
}

abstract contract AbstractTestERC721PariedBinderReleased is AbstractTestERC721PairedBinderWithCore {
    /// @notice Attack executed by contract owner of factory.
    /// Infiltrate caller requirments of bindFor/unbindFor
    /// Work by deploying collection with groupId that is bigger than groupBitWidth to gain access to tokens in other group.
    /// MUST BE SECURED IN IERC721MultipairedBinder implementation
    function testFuzz_collectionGroup_factory_attack(
        uint256 groupIdBitWidth,
        uint256 groupId,
        address owner,
        uint256 tokenId
    ) public {
        groupIdBitWidth = assumeGroup(groupId, groupIdBitWidth);
        IERC721PairedBinder binder;
        IERC721MultipairedBinder core;
        (binder, core, tokenId) = assumedCreateDuo(owner, tokenId, groupId, groupIdBitWidth);

        uint256 attackerGroupId = 1 << groupIdBitWidth | groupId;
        address attacker = CREATE3.predictDeterministicAddress(bytes32(attackerGroupId), address(this));

        vm.prank(attacker);
        vm.expectRevert();
        core.unbindFor(owner, tokenId, attackerGroupId);

        vm.prank(owner);
        binder.unbind(tokenId);

        vm.prank(attacker);
        vm.expectRevert();
        core.bindFor(owner, tokenId, attackerGroupId);
    }

    function testFuzz_effectiveOwnerOf_unboundToken(address owner, address to, uint256 tokenId) public {
        IERC721PairedBinder binder;
        IERC721MultipairedBinder core;
        (binder, core, tokenId) = assumedCreateDuoTransfer(owner, to, tokenId);

        vm.startPrank(owner);
        binder.unbind(tokenId);

        address effectiveOwner = binder.effectiveOwnerOf(tokenId);
        vm.assertEq(owner, effectiveOwner, "EffectiveOwner wrong after unbind");

        uint256 coreTokenId = core.tokenOf(_groupId, tokenId);
        core.transferFrom(owner, to, coreTokenId);
        effectiveOwner = binder.effectiveOwnerOf(tokenId);
        vm.assertEq(to, effectiveOwner, "EffectiveOwner wrong after transfer");
    }

    function testFuzz_binding_cycle(address from, address to, uint256 tokenId, uint256 groupId, uint256 groupIdBitWidth)
        public
    {
        groupIdBitWidth = assumeGroup(groupId, groupIdBitWidth);
        changeGroupMetadata(groupId, groupIdBitWidth);
        IERC721PairedBinder binder;
        IERC721MultipairedBinder core;
        (binder, core, tokenId) = assumedCreateDuoTransfer(from, to, tokenId);
        resetGroupMetadata();

        uint256 tokenIdInCore = core.tokenOf(binder.collectionGroup(), tokenId);

        //Owned by from
        vm.startPrank(from);

        vm.expectRevert();
        core.transferFrom(from, to, tokenIdInCore); //Cannot transfer; is unbound

        binder.unbind(tokenId);
        // Bound to core

        core.transferFrom(from, to, tokenIdInCore);

        //Owned by to

        address effectiveOwner = binder.effectiveOwnerOf(tokenId);
        vm.assertEq(effectiveOwner, to);

        vm.expectRevert();
        binder.bind(tokenId); // From cannot control it

        vm.startPrank(to);
        binder.bind(tokenId);
        //Bound to binder

        vm.expectRevert();
        core.transferFrom(to, from, tokenIdInCore); // Unbound from core

        core.bind(tokenIdInCore);
        //Bound to core
        core.transferFrom(to, from, tokenIdInCore);

        // Owned by from

        vm.expectRevert();
        core.unbind(tokenIdInCore); // To cannot control it.

        vm.startPrank(from);

        core.unbind(tokenIdInCore);

        // Bound to binder

        vm.expectRevert();
        core.transferFrom(from, to, tokenIdInCore);

        binder.unbind(tokenId);

        core.transferFrom(from, to, tokenIdInCore);
    }

    function testFuzz_mirroredTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 groupId,
        uint256 groupIdBitWidth
    ) public {
        groupIdBitWidth = assumeGroup(groupId, groupIdBitWidth);
        changeGroupMetadata(groupId, groupIdBitWidth);
        IERC721PairedBinder binder;
        IERC721MultipairedBinder core;
        (binder, core, tokenId) = assumedCreateDuoTransfer(from, to, tokenId);
        resetGroupMetadata();

        uint256 tokenIdInCore = core.tokenOf(binder.collectionGroup(), tokenId);

        vm.prank(from);
        binder.transferFrom(from, to, tokenId);

        address ownerInCore = core.ownerOf(tokenIdInCore);
        vm.assertEq(ownerInCore, to);

        vm.prank(to);
        binder.safeTransferFrom(to, from, tokenId);

        ownerInCore = core.ownerOf(tokenIdInCore);
        vm.assertEq(ownerInCore, from);
    }

    function testFuzz_bindersOf(address owner, uint256 tokenId, uint256 groupId, uint256 groupIdBitWidth) public {
        groupIdBitWidth = assumeGroup(groupId, groupIdBitWidth);
        IERC721PairedBinder binder;
        IERC721MultipairedBinder core;
        (binder, core, tokenId) = assumedCreateDuo(owner, tokenId, groupId, groupIdBitWidth);

        uint256 tokenIdInCore = core.tokenOf(groupId, tokenId);
        (IBindableToken[] memory collections, uint256[] memory ids) = binder.bindersOf(tokenId);
        vm.assertEq(address(collections[0]), _coreAddress());
        vm.assertEq(ids[0], tokenIdInCore);
    }
}
