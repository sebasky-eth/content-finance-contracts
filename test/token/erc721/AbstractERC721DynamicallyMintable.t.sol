// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";

import {IERC721DynamicallyMintable} from "../../../src/token/erc721/IERC721DynamicallyMintable.sol";

import {ArrayCreator} from "../../common/ArrayCreator.sol";

import {IncrementalNftTest} from "../../common/IncrementalNftTest.t.sol";

library ERC721Minter {
    function mintOneFor(
        IERC721DynamicallyMintable collection,
        address owner,
        address receiverOfTokensBefore,
        uint256 tokenId,
        string memory tokenURI,
        string memory tokensBeforeURI
    ) internal {
        if (tokenId == 0) {
            collection.safeMint(owner, tokenURI);
        } else if (tokenId == 1) {
            collection.safeMint(receiverOfTokensBefore, tokensBeforeURI);
            collection.safeMint(owner, tokenURI);
        } else {
            mintBatchedFor(collection, receiverOfTokensBefore, tokenId, tokensBeforeURI);
            collection.safeMint(owner, tokenURI);
        }
    }

    function mintOneFor(
        IERC721DynamicallyMintable collection,
        address owner,
        address receiverOfTokensBefore,
        uint256 tokenId,
        string memory tokensURI
    ) internal {
        mintOneFor(collection, owner, receiverOfTokensBefore, tokenId, tokensURI, tokensURI);
    }

    function mintManyFor(
        IERC721DynamicallyMintable collection,
        address owner,
        uint256 lastTokenId,
        string memory tokensURI
    ) internal {
        string[] memory uri = ArrayCreator.createStrings(lastTokenId + 1, tokensURI);
        collection.safeMintBatched(owner, uri);
    }

    function mintBatchedFor(
        IERC721DynamicallyMintable collection,
        address owner,
        uint256 totalTokens,
        string memory tokensURI
    ) internal {
        string[] memory uri = ArrayCreator.createStrings(totalTokens, tokensURI);
        collection.safeMintBatched(owner, uri);
    }
}

abstract contract AbstractERC721DynamicallyMintableTest is IncrementalNftTest {
    using ERC721Minter for IERC721DynamicallyMintable;

    function _maximumSupply() internal virtual returns (uint256) {
        return _maxTokenId() + 1;
    }

    function _createERC721DynamicallyMintable(uint256 maximumSupply)
        internal
        virtual
        returns (IERC721DynamicallyMintable);

    function _createERC721DynamicallyMintableFor(uint256 maximumSupply, address owner)
        internal
        virtual
        returns (IERC721DynamicallyMintable col)
    {
        assumeOwner(owner);
        col = _createERC721DynamicallyMintable(maximumSupply);
        vm.assume(address(col) != owner);
        return col;
    }

    function testFuzz_mintBatched_invalid_zeroTokens(uint256 maximumSupply, address minter) public {
        maximumSupply = bound(maximumSupply, 1, _maximumSupply());

        IERC721DynamicallyMintable col = _createERC721DynamicallyMintable(maximumSupply);

        vm.expectRevert();
        col.safeMintBatched(minter, new string[](0));
    }

    function testFuzz_mintBatched_invalid_addressZero(uint256 maximumSupply, uint256 totalTokens) public {
        maximumSupply = bound(maximumSupply, 1, _maximumSupply());
        totalTokens = bound(totalTokens, 1, _maximumSupply());

        IERC721DynamicallyMintable col = _createERC721DynamicallyMintable(maximumSupply);

        vm.expectRevert();
        col.mintBatchedFor(address(0), totalTokens, TOKEN_URI);
    }

    function testFuzz_mintByOne(uint256 maximumSupply, address minter) public {
        maximumSupply = bound(maximumSupply, 1, _smallTest());
        IERC721DynamicallyMintable col = _createERC721DynamicallyMintableFor(maximumSupply, minter);

        for (uint256 i; i < maximumSupply; i++) {
            col.safeMint(minter, TOKEN_URI);
            address owner = col.ownerOf(i);
            vm.assertEq(minter, owner);

            if (i + 1 != maximumSupply) {
                uint256 nextToken = col.nextMintedToken();
                vm.assertEq(nextToken, i + 1);
            } else {
                vm.expectRevert();
                col.nextMintedToken();
            }
        }

        uint256 balance = col.balanceOf(minter);
        vm.assertEq(balance, maximumSupply);

        vm.expectRevert();
        col.safeMint(minter, TOKEN_URI);
    }

    function testFuzz_safeMintBatched_max(uint256 maximumSupply, uint256 secMintSize, address minter) public {
        maximumSupply = bound(maximumSupply, 1, _maximumSupply());
        secMintSize = bound(secMintSize, 1, _maximumSupply());

        IERC721DynamicallyMintable col = _createERC721DynamicallyMintableFor(maximumSupply, minter);
        col.mintBatchedFor(minter, maximumSupply, TOKEN_URI);

        uint256 balance = col.balanceOf(minter);
        vm.assertEq(balance, maximumSupply, "balanceOf not equal to maximumSupply");

        bool isMintable = col.isMintable();
        vm.assertTrue(!isMintable, "'isMintable()' returns 'true'");

        vm.expectRevert();
        col.nextMintedToken();

        vm.expectRevert();
        col.mintBatchedFor(minter, secMintSize, TOKEN_URI);

        vm.expectRevert();
        col.safeMint(minter, TOKEN_URI);
    }

    function testFuzz_mintBatched_half(
        uint256 maximumSupply,
        uint256 firstMintSize,
        uint256 secMintSize,
        address minter
    ) public {
        maximumSupply = bound(maximumSupply, 2, _maximumSupply());
        firstMintSize = bound(firstMintSize, 1, maximumSupply - 1);
        secMintSize = bound(secMintSize, 1, _maximumSupply());
        vm.assume(firstMintSize + secMintSize > maximumSupply);

        IERC721DynamicallyMintable col = _createERC721DynamicallyMintableFor(maximumSupply, minter);
        col.mintBatchedFor(minter, firstMintSize, TOKEN_URI);

        uint256 nextToken = col.nextMintedToken();
        vm.assertEq(nextToken, firstMintSize);

        uint256 balance = col.balanceOf(minter);
        vm.assertEq(balance, firstMintSize);

        vm.expectRevert();
        col.mintBatchedFor(minter, secMintSize, TOKEN_URI);
    }

    function testFuzz_mintBatched_exceedsLimit(uint256 maximumSupply, uint256 mintSize, address minter) public {
        maximumSupply = bound(maximumSupply, 1, _maximumSupply() - 1);
        mintSize = bound(mintSize, maximumSupply + 1, _maximumSupply());

        IERC721DynamicallyMintable col = _createERC721DynamicallyMintable(maximumSupply);

        uint256 nextToken = col.nextMintedToken();
        vm.assertEq(nextToken, 0);

        vm.expectRevert();
        col.mintBatchedFor(minter, mintSize, TOKEN_URI);
    }

    function testFuzz_finishMints(uint256 maximumSupply, uint256 mintSize, address minter) public {
        maximumSupply = bound(maximumSupply, 2, _maximumSupply());
        mintSize = bound(mintSize, 1, maximumSupply - 1);

        IERC721DynamicallyMintable col = _createERC721DynamicallyMintableFor(maximumSupply, minter);

        col.mintBatchedFor(minter, mintSize, TOKEN_URI);
        col.finishMints();
        vm.assertEq(col.supplyLimit(), mintSize);

        bool isMintable = col.isMintable();
        vm.assertTrue(!isMintable);

        vm.expectRevert();
        col.safeMint(minter, TOKEN_URI);

        vm.expectRevert();
        col.nextMintedToken();
    }

    function testFuzz_safeMintBatched_unauthorized(uint256 maximumSupply, address unauthorizedCaller, uint256 mintSize)
        public
    {
        vm.assume(unauthorizedCaller != address(this));
        maximumSupply = bound(maximumSupply, 1, _maximumSupply());
        mintSize = bound(mintSize, 1, _maximumSupply());
        IERC721DynamicallyMintable col = _createERC721DynamicallyMintable(maximumSupply);

        vm.prank(unauthorizedCaller);
        vm.expectRevert();
        col.mintBatchedFor(unauthorizedCaller, mintSize, TOKEN_URI);
    }

    function testFuzz_safeMint_unauthorized(uint256 maximumSupply, address unauthorizedCaller) public {
        vm.assume(unauthorizedCaller != address(this));
        maximumSupply = bound(maximumSupply, 1, _maximumSupply());
        IERC721DynamicallyMintable col = _createERC721DynamicallyMintable(maximumSupply);

        vm.prank(unauthorizedCaller);
        vm.expectRevert();
        col.safeMint(unauthorizedCaller, TOKEN_URI);
    }

    function testFuzz_finishMints_unauthorized(uint256 maximumSupply, address unauthorizedCaller) public {
        vm.assume(unauthorizedCaller != address(this));
        maximumSupply = bound(maximumSupply, 1, _maximumSupply());
        IERC721DynamicallyMintable col = _createERC721DynamicallyMintable(maximumSupply);

        vm.prank(unauthorizedCaller);
        vm.expectRevert();
        col.finishMints();
    }

    function test_zeroMaximumSupply() public {
        vm.expectRevert();
        _createERC721DynamicallyMintable(0);
    }
}
