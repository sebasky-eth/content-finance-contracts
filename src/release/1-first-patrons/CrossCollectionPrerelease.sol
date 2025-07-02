// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.30;

import {CREATE3} from "solady/utils/CREATE3.sol";

import {IIncrementalOwnableFactory} from "../../factory/IncrementalOwnableFactory.sol";
import {FirstCrossCollectionalSingle} from "./FirstCrossCollectionalSingle.sol";

contract CrossCollectionPrerelease {
    function firstCrossCollectionalSingleInitCode(
        string memory name,
        string memory symbol,
        string memory cidOfContractURI,
        address initialOwner,
        address royaltyReceiver,
        uint96 feeNumerator,
        uint256 maximumSupply,
        uint256 groupIdBitWidth,
        IIncrementalOwnableFactory factory
    ) external view returns (bytes memory) {
        address mainBinder = CREATE3.predictDeterministicAddress(bytes32(0), address(factory));
        return abi.encodePacked(
            type(FirstCrossCollectionalSingle).creationCode,
            abi.encode(
                name,
                symbol,
                cidOfContractURI,
                initialOwner,
                royaltyReceiver,
                feeNumerator,
                mainBinder,
                factory.nextIteration(),
                groupIdBitWidth,
                maximumSupply
            )
        );
    }
}
