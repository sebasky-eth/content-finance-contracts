// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";

import {ERC721ContractTokenURIStorage} from
    "../../../src/token/erc721/open-zeppelin-extensions/ERC721ContractTokenURIStorage.sol";

import {IncrementalNftTest} from "../../common/IncrementalNftTest.t.sol";

abstract contract AbstractERC721ContractTokenURIStorageTest is IncrementalNftTest {
    string constant CONTRACT_URI_CID = "contractUriCid";
    string constant TOKEN_URI_CID = "tokenUriCid";
    string constant CONTRACT_URI_FULL = "ipfs://contractUriCid";
    string constant TOKEN_URI_FULL = "ipfs://tokenUriCid";

    function _createERC721ContractTokenURIStorage_IPFS(string memory contractUriCid)
        internal
        virtual
        returns (ERC721ContractTokenURIStorage);

    function _createERC721ContractTokenURIStorage_IPFS_for(
        address owner,
        uint256 tokenId,
        string memory contractUriCid,
        string memory tokenUriCid
    ) internal virtual returns (ERC721ContractTokenURIStorage);

    function _createERC721ContractTokenURIStorage_NoBase(string memory contractURI)
        internal
        virtual
        returns (ERC721ContractTokenURIStorage);

    function _createERC721ContractTokenURIStorage_NoBase_for(
        address owner,
        uint256 tokenId,
        string memory contractURI,
        string memory tokenURI
    ) internal virtual returns (ERC721ContractTokenURIStorage);

    function _createERC721ContractTokenURIStorage_forNotExistent(uint256 lastMintedToken, uint256 tokenId)
        internal
        virtual
        returns (ERC721ContractTokenURIStorage collection)
    {
        (lastMintedToken, tokenId) = boundUnminted(lastMintedToken, tokenId);
        return _createERC721ContractTokenURIStorage_IPFS_for(EOA, lastMintedToken, CONTRACT_URI_CID, TOKEN_URI_CID);
    }

    function testFuzz_tokenURI_IPFS(string memory tokenUriCid, address owner, uint256 tokenId) public {
        _assumeURI(tokenUriCid);
        tokenId = boundMintFor(owner, tokenId);
        ERC721ContractTokenURIStorage erc721 =
            _createERC721ContractTokenURIStorage_IPFS_for(owner, tokenId, CONTRACT_URI_CID, tokenUriCid);
        string memory tokenUri = erc721.tokenURI(tokenId);
        string memory expectedUri = string.concat("ipfs://", tokenUriCid);
        vm.assertEq(tokenUri, expectedUri);
    }

    function testFuzz_tokenURI_noBase(string memory tokenUri, address owner, uint256 tokenId) public {
        _assumeURI(tokenUri);
        tokenId = boundMintFor(owner, tokenId);
        ERC721ContractTokenURIStorage erc721 =
            _createERC721ContractTokenURIStorage_NoBase_for(owner, tokenId, CONTRACT_URI_FULL, tokenUri);
        vm.assertEq(erc721.tokenURI(tokenId), tokenUri);
    }

    function test_contractURI_noBase_empty(address owner, uint256 tokenId) public {
        tokenId = boundMintFor(owner, tokenId);
        ERC721ContractTokenURIStorage erc721 =
            _createERC721ContractTokenURIStorage_NoBase_for(owner, tokenId, "", TOKEN_URI_FULL);

        string memory contractURI = erc721.contractURI();
        vm.assertEq(contractURI, "");
    }

    function test_contractURI_IPFS_empty(address owner, uint256 tokenId) public {
        tokenId = boundMintFor(owner, tokenId);
        ERC721ContractTokenURIStorage erc721 =
            _createERC721ContractTokenURIStorage_IPFS_for(owner, tokenId, "", TOKEN_URI_FULL);

        string memory contractURI = erc721.contractURI();
        vm.assertEq(contractURI, "");
    }

    function testFuzz_contractURI_IPFS(string memory contractUriCid) public {
        _assumeURI(contractUriCid);

        ERC721ContractTokenURIStorage erc721 = _createERC721ContractTokenURIStorage_IPFS(contractUriCid);
        string memory contractUri = erc721.contractURI();
        string memory expectedUri = string.concat("ipfs://", contractUriCid);
        vm.assertEq(contractUri, expectedUri);
    }

    function testFuzz_contractURI_noBase(string memory contractUri) public {
        _assumeURI(contractUri);

        ERC721ContractTokenURIStorage erc721 = _createERC721ContractTokenURIStorage_NoBase(contractUri);
        vm.assertEq(erc721.contractURI(), contractUri);
    }

    function testFuzz_contractURIChange_IPFS(string memory firstContractUriCid, string memory secContractUriCid)
        public
    {
        _assumeURI(firstContractUriCid);
        _assumeURI(secContractUriCid);

        ERC721ContractTokenURIStorage erc721 = _createERC721ContractTokenURIStorage_IPFS(firstContractUriCid);

        erc721.setContractURI(secContractUriCid);

        string memory newContractUri = erc721.contractURI();
        string memory expectedContractUri = string.concat("ipfs://", secContractUriCid);
        vm.assertEq(newContractUri, expectedContractUri);
    }

    function testFuzz_contractURIChange_noBase(string memory firstContractUri, string memory secContractUri) public {
        _assumeURI(firstContractUri);
        _assumeURI(secContractUri);

        ERC721ContractTokenURIStorage erc721 = _createERC721ContractTokenURIStorage_NoBase(firstContractUri);

        erc721.setContractURI(secContractUri);

        vm.assertEq(erc721.contractURI(), secContractUri);
    }

    function testFuzz_setContractURI_rights(address unauthorizedCaller) public {
        vm.assume(unauthorizedCaller != address(this));
        ERC721ContractTokenURIStorage erc721 = _createERC721ContractTokenURIStorage_IPFS(CONTRACT_URI_CID);

        vm.prank(unauthorizedCaller);

        vm.expectRevert();
        erc721.setContractURI(CONTRACT_URI_CID);
    }

    function testFuzz_tokenURI_notExistentToken(uint256 lastMintedToken, uint256 tokenId) public {
        (lastMintedToken, tokenId) = boundUnminted(lastMintedToken, tokenId);
        ERC721ContractTokenURIStorage erc721 =
            _createERC721ContractTokenURIStorage_forNotExistent(lastMintedToken, tokenId);

        vm.expectRevert();
        erc721.tokenURI(tokenId);
    }

    function _checkURI(string memory uri) internal pure virtual returns (bool) {
        return bytes(uri).length >= 10 && bytes(uri).length <= 60;
    }

    function _assumeURI(string memory uri) internal pure virtual {
        vm.assume(_checkURI(uri));
    }
}
