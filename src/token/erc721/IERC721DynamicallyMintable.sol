// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.30;

import {IERC721DynamicSupply} from "./IERC721DynamicSupply.sol";

/**
 * @title IERC721 extension that give contract owner ability to dynamicaly mint tokens and limit how many can be minted.
 * @author Sebasky (https://github.com/sebasky-eth)
 * @notice 'tokenId' is incremental
 */
interface IERC721DynamicallyMintable is IERC721DynamicSupply {
    function safeMint(address to, string memory tokenURI) external;

    function safeMintBatched(address to, string[] memory tokenURI) external;
}
