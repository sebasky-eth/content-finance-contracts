// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.30;

import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

/**
 * @title IBinder that has ability to mirror transfer.
 * @author Sebasky (https://github.com/sebasky-eth)
 * @dev Dedicated to IERC721, but multi-owned could use it as adapter (by inheritance).
 */
interface IERC721Mirrorable is IERC721 {
    /**
     * Transfer triggered when active binder transfer 'tokenId'.
     * Reverts, if caller is not authorized binder.
     */
    function mirroredTransferFrom(address from, address to, uint256 tokenId) external;
}
