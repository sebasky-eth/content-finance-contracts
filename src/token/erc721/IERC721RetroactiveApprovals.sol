// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.30;

import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

/**
 * @title Extend approval logic with ability to disable all approvals that was made before 'retroactiveDate'.
 * @author Sebasky (https://github.com/sebasky-eth)
 */
interface IERC721RetroactiveApprovals is IERC721 {
    event RetroactiveApproval(address indexed owner, uint256 retroactiveDate);

    /**
     * @notice Returns a date, which turns off all approvals of 'owner' granted before it.
     */
    function retroactiveDate(address owner) external view returns (uint256);

    /**
     * @notice Returns time when IERC721.setApprovalForAll was made. '0' - is not approved.
     */
    function approvalDate(address owner, address operator) external view returns (uint256 date);

    /**
     * @notice Returns date when IERC721.getApproved was made. '0' - is not approved.
     */
    function tokenApprovalDate(uint256 tokenId) external view returns (uint256 date);

    /**
     * @notice Disable all caller's approvals that was made before 'date'.
     * @dev Emit RetroactiveApproval(date).
     */
    function disableAllApprovalsBefore(uint256 date) external;

    /**
     * @notice Disable all current caller's approvals.
     * Can be enabled again with: disableAllApprovalsBefore(0).
     * @dev Emit RetroactiveApproval(block.timestamp + 1)
     */
    function disableAllApprovals() external;
}
