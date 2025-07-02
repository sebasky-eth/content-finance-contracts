// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.30;

import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

/**
 * @title Extension for ERC721 that limit dynamic minting mechanism.
 * @author Sebasky (https://github.com/sebasky-eth)
 * @notice For incremental tokenId.
 */
interface IERC721DynamicSupply is IERC721 {
    function nextMintedToken() external view returns (uint256);

    function supplyLimit() external view returns (uint256);

    function isMintable() external view returns (bool);

    function finishMints() external;
}
