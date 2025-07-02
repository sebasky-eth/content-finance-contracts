// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";

abstract contract NftTest is Test {
    /// @notice When ownership is unimportant.
    address EOA = vm.addr(uint256(keccak256("EOA")));
    string TOKEN_URI = "ipfs://tokenURI";

    function _checkOwner(address owner) internal view returns (bool) {
        return owner != address(0) && owner.code.length == 0;
    }

    function _checkTransferable(address from, address to) internal view returns (bool) {
        return _checkOwner(from) && _checkOwner(to) && from != to;
    }

    function assumeOwner(address owner) internal view {
        vm.assume(_checkOwner(owner));
    }

    function assumeTrasferTarget(address from, address to) internal view {
        vm.assume(from != to && _checkOwner(to));
    }

    function test_NftTest_constants() public view {
        vm.assertTrue(EOA.code.length == 0, "EOA cannot be contract");
    }
}
