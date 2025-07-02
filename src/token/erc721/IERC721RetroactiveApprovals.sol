// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.30;

import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

/**
 * @title Extend approval logic with ability to disable all approvals that was made before 'retroactiveDate'.
 * @author Sebasky (https://github.com/sebasky-eth)
 */
interface IERC721RetroactiveApprovals is IERC721 {
    event RetroactiveApproval(address indexed owner, uint256 indexed retroactiveDate);

    /**
     * @notice Disable all approvals for caller without deleting them.
     * @dev Doesn't emit classic IERC721 approval events.
     * @param retroactiveDate - If 0 is passed, then all approvals will be working as usual. Cannot be bigger than current date.
     * If time is bigger than 0, it will disable all approvals that was made before it.
     */
    function disableAllApprovalsBefore(uint256 retroactiveDate) external;

    /**
     * @notice Disable all current approvals for caller without deleting them.
     * Can be enabled again with: disableAllApprovalsBefore(0).
     * Equivalent to disableAllApprovalsBefore(block.timestamp + 1); if argument like that would be allowed
     */
    function disableAllApprovals() external;

    /**
     * @notice Returns date when operator approval was changed by 'owner'.
     * @return date - time when latest approval was made. '0' could mean that approval was never changed.
     */
    function approvalChangeDate(address owner, address operator) external view returns (uint256 date);

    /**
     * @notice Returns date when token approval was lastly changed.
     * @return date - time when latest approval was made. '0' mean that approval was never changed in current ownership.
     */
    function tokenApprovalChangeDate(uint256 tokenId) external view returns (uint256 date);

    /**
     * @notice Returns a date, which turns off all approvals for 'owner' granted before it.
     * @return date - time when latest approval was made. '0' mean that approval was never changed.
     */
    function approvalsRetroactiveDate(address owner) external view returns (uint256);
}
