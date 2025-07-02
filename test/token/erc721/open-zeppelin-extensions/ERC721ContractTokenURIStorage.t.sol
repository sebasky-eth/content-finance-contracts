// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AbstractERC721ContractTokenURIStorageTest} from "../AbstractERC721ContractTokenURIStorage.t.sol";

import {ERC721ContractTokenURIStorage} from
    "../../../../src/token/erc721/open-zeppelin-extensions/ERC721ContractTokenURIStorage.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ERC721Minter} from "../AbstractERC721DynamicallyMintable.t.sol";
import {
    FirstCrossCollectionalSingle,
    IERC721MultipairedBinder
} from "../../../../src/release/1-first-patrons/FirstCrossCollectionalSingle.sol";

import {IncrementalNftTest} from "../../../common/IncrementalNftTest.t.sol";

contract NoBaseMockup is ERC721, ERC721ContractTokenURIStorage {
    constructor(address initialOwner, string memory contractUri)
        ERC721("MyToken", "MTK")
        Ownable(initialOwner)
        ERC721ContractTokenURIStorage(contractUri)
    {}

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721ContractTokenURIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721ContractTokenURIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

contract NoBaseMintableMockup is ERC721, ERC721ContractTokenURIStorage {
    constructor(
        address initialOwner,
        string memory contractUri,
        address receiver,
        uint256 tokenId,
        string memory tokenUri
    ) ERC721("MyToken", "MTK") Ownable(initialOwner) ERC721ContractTokenURIStorage(contractUri) {
        _safeMint(receiver, tokenId);
        _setTokenURI(tokenId, tokenUri);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721ContractTokenURIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721ContractTokenURIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

contract ERC721ContractTokenURIStorageTest is AbstractERC721ContractTokenURIStorageTest {
    using ERC721Minter for FirstCrossCollectionalSingle;

    IERC721MultipairedBinder CORE = IERC721MultipairedBinder(vm.addr(uint256(keccak256("CORE"))));

    function _createFirstCrossCollectionalSingle(string memory contractUriCid)
        private
        returns (FirstCrossCollectionalSingle)
    {
        address contractOwner = address(this);
        return new FirstCrossCollectionalSingle(
            "MetadataName",
            "MetadataSymbol",
            contractUriCid,
            contractOwner,
            address(this),
            1000,
            CORE,
            1,
            32,
            _maxTokenId() + 1
        );
    }

    function _createERC721ContractTokenURIStorage_IPFS(string memory contractUriCid)
        internal
        virtual
        override
        returns (ERC721ContractTokenURIStorage)
    {
        return _createFirstCrossCollectionalSingle(contractUriCid);
    }

    function _createERC721ContractTokenURIStorage_IPFS_for(
        address owner,
        uint256 tokenId,
        string memory contractUriCid,
        string memory tokenUriCid
    ) internal virtual override returns (ERC721ContractTokenURIStorage) {
        FirstCrossCollectionalSingle col = _createFirstCrossCollectionalSingle(contractUriCid);
        col.mintOneFor(owner, EOA, tokenId, tokenUriCid);
        vm.assume(address(col) != owner && address(col) != EOA);
        return col;
    }

    function _createERC721ContractTokenURIStorage_NoBase(string memory contractURI)
        internal
        virtual
        override
        returns (ERC721ContractTokenURIStorage)
    {
        return new NoBaseMockup(address(this), contractURI);
    }

    function _createERC721ContractTokenURIStorage_NoBase_for(
        address owner,
        uint256 tokenId,
        string memory contractURI,
        string memory tokenURI
    ) internal virtual override returns (ERC721ContractTokenURIStorage col) {
        col = new NoBaseMintableMockup(address(this), contractURI, owner, tokenId, tokenURI);
        vm.assume(address(col) != owner);
    }
}
