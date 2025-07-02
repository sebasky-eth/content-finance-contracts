// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";

import {NftTest} from "./NftTest.t.sol";

/**
 * @title Util functions for testing nft collections including these with incremental minting.
 * @author
 */
abstract contract IncrementalNftTest is NftTest {
    ///@notice How many tokens are minted in tests where ALL will be tested.
    function _smallTest() internal pure virtual returns (uint256) {
        return 100;
    }

    /// @notice Max tokens minted in collection
    function _maxTokenId() internal pure virtual returns (uint256) {
        return 1000;
    }

    function _checkToken(uint256 tokenId) internal pure returns (bool) {
        return tokenId <= _maxTokenId();
    }

    function _checkUnmintedToken(uint256 lastMinted, uint256 tokenId) internal pure returns (bool) {
        return _checkToken(tokenId) && tokenId > lastMinted;
    }

    function boundToken(uint256 tokenId) internal pure returns (uint256) {
        return bound(tokenId, 0, _maxTokenId());
    }

    function boundUnminted(uint256 lastMinted, uint256 tokenId) internal pure returns (uint256, uint256) {
        lastMinted = bound(lastMinted, 0, _maxTokenId() - 2);
        tokenId = bound(tokenId, lastMinted + 1, _maxTokenId());
        return (lastMinted, tokenId);
    }

    function boundMintFor(address owner, uint256 tokenId) internal view returns (uint256) {
        vm.assume(_checkOwner(owner));
        return boundToken(tokenId);
    }

    function boundTranferFrom(address from, address to, uint256 tokenId) internal view returns (uint256) {
        vm.assume(_checkTransferable(from, to));
        return boundToken(tokenId);
    }

    function test_IncrementalNftTest_constants() public pure {
        vm.assertTrue(_smallTest() <= _maxTokenId(), "'_smallTest' tests must be smaller that '_maxTokenId'");
    }
}
