// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {CREATE3} from "solady/utils/CREATE3.sol";

import {IERC721PairedBinder} from "../../../../src/token/erc721/IERC721PairedBinder.sol";
import {IERC721MultipairedBinder} from "../../../../src/token/erc721/IERC721MultipairedBinder.sol";

import {ERC721PairedBinderPrelaunched} from
    "../../../../src/token/erc721/open-zeppelin-extensions/ERC721PairedBinderPrelaunched.sol";
import {FirstCrossCollectionalSingle} from "../../../../src/release/1-first-patrons/FirstCrossCollectionalSingle.sol";

import {ERC721Minter} from "../AbstractERC721DynamicallyMintable.t.sol";

import {
    AbstractTestERC721PairedBinder,
    AbstractTestERC721PairedBinderWithCore,
    AbstractTestERC721PairedBinderCoreAgnostic,
    AbstractTestERC721PairedBinderPrereleased,
    AbstractTestERC721PariedBinderReleased,
    AbstractTestERC721PairedBinderBuggedCore
} from "../AbstractERC721PairedBinder.t.sol";

import {FirstCrossCollectionalSingle} from "../../../../src/release/1-first-patrons/FirstCrossCollectionalSingle.sol";

/// @notice Mockup for testing ERC721PairedBinder released before core to make sure that balance and ownership is secured.
contract BuggyCoreMockup {
    /// @notice Accepts everything
    function bindFor(address owner, uint256 tokenId, uint256 groupId) external {}

    /// @notice Accepts everything
    function unbindFor(address owner, uint256 tokenId, uint256 groupId) external {}

    /// @notice Always return address(0)
    function effectiveOwnerOf(uint256 tokenId) external returns (address) {}
}

/// @notice Mockup for testing ERC721PairedBinder - IERC721MultipairedBinder integrations.
/// @dev NEVER USE AS IERC721MultipairedBinder. It only implements small portion of functionalities.
contract CoreMockup {
    uint256 private constant ADDRESS_MASK = (1 << 160) - 1;

    uint256 private immutable _groupIdBitWidth;
    uint256 private immutable _tokenBitWidth;
    uint256 private immutable _groupMask;

    address private immutable _factory;

    mapping(uint256 tokenId => uint256 ownershipBitfield) private _owners;

    constructor(address factory, uint256 groupIdBitWidth, address receiver, uint256 tokenId, uint256 groupId) {
        _groupIdBitWidth = groupIdBitWidth;
        _tokenBitWidth = 256 - _groupIdBitWidth;
        _groupMask = (1 << groupIdBitWidth) - 1;
        _factory = factory;
        _mint(receiver, _requireTokenOf(groupId, tokenId));
    }

    function _mint(address receiver, uint256 tokenId) internal {
        _changeOwnership(tokenId, receiver, 0);
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        return address(uint160(_owners[tokenId] & ADDRESS_MASK));
    }

    function _requireOwned(uint256 tokenId) internal view returns (address owner) {
        owner = _ownerOf(tokenId);
        require(owner != address(0));
    }

    function _changeOwnership(uint256 tokenId, address owner, uint256 _isBound) internal {
        uint256 bitfield = uint256(uint160(owner)) | (_isBound << 160);
        _owners[tokenId] = bitfield;
    }

    function _interpretateTokenBitfield(uint256 tokenBitfield)
        internal
        pure
        returns (address owner, uint256 _isBound)
    {
        owner = address(uint160(tokenBitfield & ADDRESS_MASK));
        _isBound = (tokenBitfield >> 160) & 1;
    }

    function _getBinder(uint256 groupId) internal view returns (address) {
        return CREATE3.predictDeterministicAddress(bytes32(groupId), _factory);
    }

    function _requireBinder(uint256 groupId) internal view {
        address authorizedCaller = _getBinder(groupId);
        require(msg.sender == authorizedCaller, CallerMustBeBinder(msg.sender, authorizedCaller));
    }

    function _interpretateToken(uint256 tokenIdInGroup, uint256 groupId)
        internal
        view
        returns (uint256 tokenId, address owner, uint256 _isBound)
    {
        tokenId = _requireTokenOf(groupId, tokenIdInGroup);
        (owner, _isBound) = _interpretateTokenBitfield(_owners[tokenId]);
    }

    function _bindingFor(address owner, uint256 tokenId, uint256 groupId, uint256 willBeBound) internal {
        require(owner != address(0), WrongOwner(owner));
        _requireBinder(groupId);
        (uint256 tokenIdHere, address ownerHere, uint256 _isBound) = _interpretateToken(tokenId, groupId);
        require(owner == ownerHere, InvalidOwner(tokenIdHere, msg.sender, ownerHere));
        require(_isBound != willBeBound, InvalidBindingChange(_isBound == 1));
        _changeOwnership(tokenIdHere, ownerHere, willBeBound);
    }

    function _binding(address caller, uint256 tokenId, uint256 willBeBound) internal {
        (address owner, uint256 _isBound) = _interpretateTokenBitfield(_owners[tokenId]);
        require(owner != address(0), WrongOwner(owner));
        require(caller == owner, CallerIsNotOwner(caller, owner));
        require(willBeBound != _isBound, InvalidBindingChange(_isBound == 1));
        (uint256 groupId, uint256 tokenIdInGroup) = groupOf(tokenId);
        IERC721PairedBinder binder = IERC721PairedBinder(_getBinder(groupId));
        if (willBeBound == 0) {
            binder.bindFor(owner, tokenIdInGroup);
        } else {
            binder.unbindFor(owner, tokenIdInGroup);
        }
        _changeOwnership(tokenId, owner, willBeBound);
    }

    function _tokenOf(uint256 groupId, uint256 tokenId) internal view returns (uint256) {
        return tokenId << _groupIdBitWidth | groupId;
    }

    function _requireTokenOf(uint256 groupId, uint256 tokenId) internal view returns (uint256) {
        require((groupId >> _groupIdBitWidth) == 0, InvalidGroupId(groupId));
        require((tokenId >> _tokenBitWidth) == 0, InvalidTokenInGroup(tokenId, groupId));
        return _tokenOf(groupId, tokenId);
    }

    /*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
            Used in tests:
    -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/
    error WrongOwner(address owner);
    error CallerMustBeBinder(address caller, address binder);
    error InvalidGroupId(uint256 groupId);
    error InvalidTokenInGroup(uint256 tokenId, uint256 groupId);
    error InvalidOwner(uint256 tokenId, address caller, address owner);
    error InvalidBindingChange(bool isBound);
    error CallerIsNotOwner(address caller, address owner);

    function groupOf(uint256 tokenId) public view returns (uint256 groupId, uint256 tokenIdInGroup) {
        groupId = tokenId & _groupMask;
        tokenIdInGroup = tokenId >> _groupIdBitWidth;
    }

    function tokenOf(uint256 groupId, uint256 tokenId) public view returns (uint256 token) {
        token = _requireTokenOf(groupId, tokenId);
        _requireOwned(token);
    }

    function groupMetaData() external view returns (uint256 offsetInTokenId, uint256 bitWidthInTokenId) {
        return (_groupIdBitWidth, _tokenBitWidth);
    }

    function effectiveOwnerOf(uint256 tokenId) external view returns (address) {
        return _requireOwned(tokenId);
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return _requireOwned(tokenId);
    }

    function isBound(uint256 tokenId) public view returns (bool) {
        return (_owners[tokenId] >> 160) & 1 == 1;
    }

    function bindFor(address owner, uint256 tokenId, uint256 groupId) external {
        _bindingFor(owner, tokenId, groupId, 1);
    }

    function unbindFor(address owner, uint256 tokenId, uint256 groupId) external {
        _bindingFor(owner, tokenId, groupId, 0);
    }

    function bind(uint256 tokenId) external {
        _binding(msg.sender, tokenId, 1);
    }

    function unbind(uint256 tokenId) external {
        _binding(msg.sender, tokenId, 0);
    }

    function mirroredTransferFrom(address from, address to, uint256 tokenId, uint256 groupId) external {
        require(to != address(0));
        _requireBinder(groupId);

        (uint256 tokenIdHere, address ownerHere, uint256 _isBound) = _interpretateToken(tokenId, groupId);
        require(from == ownerHere);

        //Assume that token can has only one bound (Like in {ERC721PairedBinderPrelaunched})
        require(_isBound == 0);
        _changeOwnership(tokenIdHere, to, 0);
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        require(to != address(0));
        require(msg.sender == from);

        (address owner, uint256 _isBound) = _interpretateTokenBitfield(_owners[tokenId]);
        require(owner == from);
        require(_isBound == 1);

        _changeOwnership(tokenId, to, 1);
    }
}

abstract contract ERC721PairedBinderTest is AbstractTestERC721PairedBinder {
    using ERC721Minter for FirstCrossCollectionalSingle;

    function _createFirstCrossCollectionalSingle() internal virtual returns (FirstCrossCollectionalSingle) {
        address contractOwner = address(this);
        return new FirstCrossCollectionalSingle(
            "MetadataName",
            "MetadataSymbol",
            "ContractURI",
            contractOwner,
            address(this),
            1000,
            IERC721MultipairedBinder(_coreAddress()),
            _groupId,
            _groupIdBitWidth,
            _maxTokenId() + 1
        );
    }

    /// @notice Return collection where 'tokenId' is minted for minter and all tokens before are minted for 'EOA'
    function _createMintedFor(address minter, uint256 tokenId)
        internal
        virtual
        override
        returns (IERC721PairedBinder)
    {
        vm.assume(minter != _coreAddress());
        FirstCrossCollectionalSingle col = _createFirstCrossCollectionalSingle();
        vm.assume(address(col) != minter && address(col) != EOA);
        col.mintOneFor(minter, EOA, tokenId, TOKEN_URI);
        return col;
    }

    /// @notice Return collection without any minted tokens.
    function _createPairedBinder() internal virtual override returns (IERC721PairedBinder) {
        FirstCrossCollectionalSingle col = _createFirstCrossCollectionalSingle();
        return col;
    }
}

abstract contract ERC721PairedBinderWithoutCore is ERC721PairedBinderTest {
    IERC721MultipairedBinder CORE = IERC721MultipairedBinder(vm.addr(uint256(keccak256("CORE"))));

    function _coreAddress() internal virtual override returns (address) {
        return address(CORE);
    }
}

abstract contract ERC721PairedBinderWithCore is ERC721PairedBinderTest, AbstractTestERC721PairedBinderWithCore {
    function _setupCoreInitCode(address minter, uint256 tokenId) internal virtual returns (bytes memory);

    function _createFirstCrossCollectionalSingle() internal virtual override returns (FirstCrossCollectionalSingle) {
        address contractOwner = address(this);

        bytes memory initCode = abi.encodePacked(
            type(FirstCrossCollectionalSingle).creationCode,
            abi.encode(
                "MetadataName",
                "MetadataSymbol",
                "ContractURI",
                contractOwner,
                address(this),
                1000,
                IERC721MultipairedBinder(_coreAddress()),
                _groupId,
                _groupIdBitWidth,
                _maxTokenId() + 1
            )
        );

        return FirstCrossCollectionalSingle(_deployFromDeployer(initCode, _groupId));
    }

    function _coreAddress() internal virtual override returns (address) {
        return CREATE3.predictDeterministicAddress(0, address(this));
    }

    function _deployFromDeployer(bytes memory initCode, uint256 groupId) internal virtual returns (address) {
        return CREATE3.deployDeterministic(initCode, bytes32(groupId));
    }

    function _createCoreMintedFor(address minter, uint256 tokenId)
        internal
        virtual
        override
        returns (IERC721MultipairedBinder col)
    {
        bytes memory initCode = _setupCoreInitCode(minter, tokenId);
        col = IERC721MultipairedBinder(_deployFromDeployer(initCode, 0));
        vm.assume(minter != address(col));
    }
}

contract ERC721PairedBinderCoreAgnosticTest is
    ERC721PairedBinderTest,
    ERC721PairedBinderWithoutCore,
    AbstractTestERC721PairedBinderCoreAgnostic
{}

contract ERC721PairedBinderPrereleasedTest is
    AbstractTestERC721PairedBinderPrereleased,
    ERC721PairedBinderTest,
    ERC721PairedBinderWithoutCore
{}

contract ERC721PairedBinderBuggedCoreTest is ERC721PairedBinderWithCore, AbstractTestERC721PairedBinderBuggedCore {
    function _setupCoreInitCode(address minter, uint256 tokenId) internal virtual override returns (bytes memory) {
        return type(BuggyCoreMockup).creationCode;
    }
}

contract ERC721PariedBinderReleasedTest is ERC721PairedBinderWithCore, AbstractTestERC721PariedBinderReleased {
    function _setupCoreInitCode(address minter, uint256 tokenId) internal virtual override returns (bytes memory) {
        //address factory, uint256 groupIdBitWidth, address receiver, uint256 tokenId, uint256 groupId
        return abi.encodePacked(
            type(CoreMockup).creationCode, abi.encode(address(this), _groupIdBitWidth, minter, tokenId, _groupId)
        );
    }
}
