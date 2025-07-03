// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.30;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {CREATE3} from "solady/utils/CREATE3.sol";

import {IIncrementalOwnableFactory} from "./IIncrementalOwnableFactory.sol";

/**
 * @title Ownable factory of custom contracts that are deployed with incrementally increased salt.
 * @author Sebasky (https://github.com/sebasky-eth)
 * @notice Used for IBindableToken.
 * Core collection MUST emit event that points to factory address and be deployed with salt=0 {IIncrementalOwnableFactory.deployBase}.
 */
contract IncrementalOwnableFactory is Ownable, IIncrementalOwnableFactory {
    uint256 private _previousIteration;

    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @notice Returns if 'base' contract was deployed (CREATE3 with salt = 0).
     */
    function wasBaseDeployed() external view returns (bool) {
        return predictAddress(0).code.length != 0;
    }

    /**
     * @notice Returns next iteration that will be used for salt.
     */
    function nextIteration() external view returns (uint256) {
        return _previousIteration + 1;
    }

    /**
     * @notice Deploy base contract (CREATE3 with salt = 0)
     * @return base - address of deployed contract.
     * Reverts, if base was already deployed.
     * Reverts, if caller is not 'owner'.
     */
    function deployBase(bytes memory initCode) external onlyOwner returns (address base) {
        base = CREATE3.deployDeterministic(initCode, 0);
    }

    /**
     * @notice Deploy contract with 'nextIteration' as CREATE3 salt and increase 'nextIteration'.
     * Returns address of deployed contract.
     * Reverts, if caller is not 'owner'.
     */
    function deploy(bytes memory initCode) external onlyOwner returns (address contractAdr) {
        uint256 current = _previousIteration + 1;

        contractAdr = CREATE3.deployDeterministic(initCode, bytes32(current));

        _previousIteration = current;
    }

    function predictAddress(uint256 iteration) public view returns (address) {
        return CREATE3.predictDeterministicAddress(bytes32(iteration));
    }
}
