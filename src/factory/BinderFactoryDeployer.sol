// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {CREATE3} from "solady/utils/CREATE3.sol";

import {IncrementalOwnableFactory} from "./IncrementalOwnableFactory.sol";

/**
 * @title Factory of IncrementalOwnableFactory (or custom code) with deterministic address.
 * @author Sebasky (https://github.com/sebasky-eth)
 * @notice
 */
contract BinderFactoryDeployer {
    bytes32 private constant _incrementalOwnableFactoryCodeHash =
        keccak256(type(IncrementalOwnableFactory).creationCode);

    function saltOf(address deployer, string memory collectionName) public pure returns (bytes32) {
        return keccak256(abi.encode(deployer, collectionName));
    }

    function addressOf(address deployer, string memory collectionName) public view returns (address) {
        return CREATE3.predictDeterministicAddress(saltOf(deployer, collectionName));
    }

    function incrementalOwnableFactoryInitCode(address owner) public pure returns (bytes memory) {
        return abi.encodePacked(type(IncrementalOwnableFactory).creationCode, abi.encode(owner));
    }

    function incrementalOwnableFactoryBytecode() public pure returns (bytes memory) {
        return type(IncrementalOwnableFactory).creationCode;
    }

    function incrementalOwnableFactoryCodehash() public pure returns (bytes32) {
        return _incrementalOwnableFactoryCodeHash;
    }

    ///@notice Deploy custom factory with address based on 'collectionName' and caller.
    ///@dev Revert if name is not unique for caller.
    function deployFactory(string memory collectionName, bytes memory initCode) public returns (address) {
        bytes32 salt = saltOf(msg.sender, collectionName);
        return CREATE3.deployDeterministic(initCode, salt);
    }

    ///@notice Deploy incremental ownable factory with address based on 'collectionName' and caller.
    ///@dev Revert if name is not unique for caller.
    function deployIncrementalOwnableFactory(string memory collectionName, address contractOwner)
        external
        returns (address)
    {
        return deployFactory(collectionName, incrementalOwnableFactoryInitCode(contractOwner));
    }
}
