// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";

import {CrossCollectionPrerelease} from "../../src/release/1-first-patrons/CrossCollectionPrerelease.sol";
import {IncrementalOwnableFactory, IIncrementalOwnableFactory} from "../../src/factory/IncrementalOwnableFactory.sol";
import {BinderFactoryDeployer} from "../../src/factory/BinderFactoryDeployer.sol";

contract CrossCollectionPrereleaseTest is Test {
    /*
    string memory name,
    string memory symbol,
    string memory cidOfContractURI,
    address initialOwner,
    address royaltyReceiver,
    uint96 feeNumerator,
    uint256 maximumSupply,
    uint256 groupIdBitWidth,
    IIncrementalOwnableFactory factory
    */
    CrossCollectionPrerelease helper;
    BinderFactoryDeployer factoryDeployer;
    IIncrementalOwnableFactory factory;
    string COLLECTION__NAME = "Collection Name";

    uint256 constant TOTAL_TESTS = 10;

    function setUp() public {
        factoryDeployer = new BinderFactoryDeployer();
        factory =
            IIncrementalOwnableFactory(factoryDeployer.deployIncrementalOwnableFactory(COLLECTION__NAME, address(this)));
        helper = new CrossCollectionPrerelease();
    }

    function test_CrossCollectionPrerelease() public {
        address predictedAddress = factoryDeployer.addressOf(address(this), COLLECTION__NAME);
        vm.assertEq(predictedAddress, address(factory));
        for (uint256 i = 0; i < TOTAL_TESTS; i++) {
            bytes memory initCode = helper.firstCrossCollectionalSingleInitCode(
                "name", "symbol", "contractURI", address(this), address(this), 1000, 100, 32, factory
            );
            uint256 nextIteration = factory.nextIteration();
            vm.assertEq(nextIteration, i + 1);

            factory.deploy(initCode);
        }
    }
}
