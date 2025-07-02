// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AbstractERC721DynamicallyMintableTest} from "../AbstractERC721DynamicallyMintable.t.sol";

import {IERC721DynamicallyMintable} from
    "../../../../src/token/erc721/open-zeppelin-extensions/ERC721DynamicallyMintable.sol";
import {IERC721MultipairedBinder} from "../../../../src/token/erc721/IERC721MultipairedBinder.sol";

import {FirstCrossCollectionalSingle} from "../../../../src/release/1-first-patrons/FirstCrossCollectionalSingle.sol";

contract ERC721DynamicallyMintableTest is AbstractERC721DynamicallyMintableTest {
    IERC721MultipairedBinder CORE = IERC721MultipairedBinder(vm.addr(uint256(keccak256("CORE"))));

    function _createERC721DynamicallyMintable(uint256 maximumSupply)
        internal
        virtual
        override
        returns (IERC721DynamicallyMintable)
    {
        address contractOwner = address(this);
        return new FirstCrossCollectionalSingle(
            "MetadataName",
            "MetadataSymbol",
            "ContractURI",
            contractOwner,
            address(this),
            1000,
            CORE,
            1,
            32,
            maximumSupply
        );
    }
}
