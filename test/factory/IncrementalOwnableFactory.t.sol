// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";

import {IncrementalOwnableFactory} from "../../../src/factory/IncrementalOwnableFactory.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Mockup {
    uint256 private _seed;

    constructor(uint256 initial) {
        _seed = initial;
    }

    function seed() external view returns (uint256) {
        return _seed;
    }
}

contract PredictionDeploymentRightsTests is Test {
    uint256 constant PREDICTION_TEST_TRIES = 50;

    uint256 constant SEED = 42;

    function _verifyMockupDeployment(Mockup mockup) internal view returns (bool) {
        return mockup.seed() == SEED;
    }

    function _mockupInitCode() internal pure returns (bytes memory) {
        return abi.encodePacked(type(Mockup).creationCode, abi.encode(SEED));
    }

    function testFuzz_basePrediction(address owner) public {
        vm.assume(owner != address(0));
        IncrementalOwnableFactory factory = new IncrementalOwnableFactory(owner);
        address predictedBase = factory.predictAddress(0);

        vm.prank(owner);
        address base = factory.deployBase(_mockupInitCode());
        vm.assertEq(predictedBase, base);
    }

    function testFuzz_iteratedDeployment(address owner) public {
        vm.assume(owner != address(0));

        vm.startPrank(owner);
        IncrementalOwnableFactory factory = new IncrementalOwnableFactory(owner);

        address predictedLastRelease = factory.predictAddress(PREDICTION_TEST_TRIES);
        address release;
        for (uint256 i = 1; i <= PREDICTION_TEST_TRIES; i++) {
            uint256 iteration = factory.nextIteration();
            vm.assertEq(iteration, i);
            address predictedRelease = factory.predictAddress(iteration);
            release = factory.deploy(_mockupInitCode());
            vm.assertEq(predictedRelease, release);
            vm.assertTrue(_verifyMockupDeployment(Mockup(release)));
        }
        vm.assertEq(predictedLastRelease, release);
    }

    function test_baseDeployment() public {
        IncrementalOwnableFactory factory = new IncrementalOwnableFactory(address(this));
        address mockupAddress = factory.deployBase(_mockupInitCode());
        vm.assertTrue(_verifyMockupDeployment(Mockup(mockupAddress)));
    }

    function testFuzz_deploymentRights(address owner, address unauthorizedCaller) public {
        vm.assume(owner != address(0) && unauthorizedCaller != owner);

        IncrementalOwnableFactory factory = new IncrementalOwnableFactory(owner);

        vm.startPrank(unauthorizedCaller);

        vm.expectRevert();
        factory.deployBase(_mockupInitCode());

        vm.expectRevert();
        factory.deploy(_mockupInitCode());
    }
}
