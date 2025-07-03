// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {CREATE3} from "solady/utils/CREATE3.sol";

import {IIncrementalOwnableFactory} from "../../factory/IncrementalOwnableFactory.sol";
import {FirstCrossCollectionalSingle} from "./FirstCrossCollectionalSingle.sol";

/**
 * @title Generator of init code for 'FirstCrossCollectionalSingle'
 * @author Sebasky (https://github.com/sebasky-eth)
 */
contract CrossCollectionPrerelease {
    /**
     * @param name - collection name.
     * @param symbol - collection symbol.
     * @param cidOfContractURI - "ipfs://[cid]" of contractURI.
     * @param initialOwner - contract owner {Ownable}.
     * @param royaltyReceiver - receiver of royality {ERC2981}.
     * @param feeNumerator - royality information in basis points (1 basis point = 0.01%).
     * @param maximumSupply - maximum amount of tokens in collection. If 0: will be calculated. Can be decreased after deployment with {changeSupplyLimit}.
     * @param groupIdBitWidth - how many bits groupId will have in coreBinder
     * @param factory - address of factory that will deploy this contract, core collection and every other binder.
     */
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
