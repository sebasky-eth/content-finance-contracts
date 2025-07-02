// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.30;

/**
 * @title Ownable factory of custom contracts that are deployed with incrementally increased salt.
 * @author Sebasky (https://github.com/sebasky-eth)
 */
interface IIncrementalOwnableFactory {
    /**
     * @notice Returns if 'base' contract was deployed (CREATE3 with salt = 0).
     */
    function wasBaseDeployed() external view returns (bool);

    /**
     * @notice Returns iteration that was used in last contract for salt.
     * Reverts, if there is too much iterations (2^256-1)
     */
    function nextIteration() external view returns (uint256);

    /**
     * @notice Returns address of contract deployed (now or in future) by this factory based on 'iteration'.
     * @param iteration - iteration of deployed contract. If '0': returns address of 'base'.
     */
    function predictAddress(uint256 iteration) external view returns (address);

    /**
     * @notice Deploy base contract (CREATE3 with salt = 0)
     * Reverts, if base was already deployed.
     * Reverts, if caller is not 'owner'.
     */
    function deployBase(bytes memory initCode) external returns (address base);

    /**
     * @notice Deploy contract with 'nextIteration' as CREATE3 salt and increase 'nextIteration'.
     * Reverts, if caller is not 'owner'.
     * Reverts, if there is too much iterations (2^256-1)
     */
    function deploy(bytes memory initCode) external returns (address base);
}
