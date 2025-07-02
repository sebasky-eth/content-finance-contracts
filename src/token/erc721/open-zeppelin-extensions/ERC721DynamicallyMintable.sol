// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0

pragma solidity ^0.8.30;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import {IERC721DynamicallyMintable} from "../IERC721DynamicallyMintable.sol";

/**
 * @title ERC721 extension (for OpenZeppelin base) that add dynamic minting with limits that can be reduced, but not increased.
 * @author Sebasky (https://github.com/sebasky-eth)
 */
abstract contract ERC721DynamicallyMintable is ERC721, ERC721URIStorage, Ownable, IERC721DynamicallyMintable {
    error MaximumSupplyCannotBeZero();
    error ExceedsSupplyLimit(uint256 limit, uint256 newSupply);
    error MintingAlreadyFinished();

    uint256 private _nextTokenId;
    uint256 internal immutable _supplyLimit;
    uint256 private _skippedForLimit;

    constructor(uint256 maximumSupply) {
        require(maximumSupply != 0, MaximumSupplyCannotBeZero());
        _supplyLimit = maximumSupply;
    }

    /*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
            IERC721DynamicSupply
    -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/

    function isMintable() external view virtual returns (bool) {
        return _nextTokenId != _supplyLimit;
    }

    function supplyLimit() external view virtual returns (uint256) {
        unchecked {
            return _supplyLimit - _skippedForLimit;
        }
    }

    /**
     * @notice Return tokenId of next minted token.
     * Reverts, if tokens cannot be minted.
     */
    function nextMintedToken() external view virtual returns (uint256) {
        uint256 nextTokenId = _nextTokenId;
        _requireMintable(nextTokenId);
        return nextTokenId;
    }

    function finishMints() external virtual onlyOwner {
        uint256 missing;
        unchecked {
            missing = _supplyLimit - _nextTokenId;
        }
        require(missing != 0, MintingAlreadyFinished());
        _nextTokenId = _supplyLimit;
        _skippedForLimit = missing;
    }

    /*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
            IERC721DynamicallyMintable
    -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/

    function safeMint(address to, string memory uri) external virtual onlyOwner {
        uint256 tokenId = _nextTokenId;
        _requireMintable(tokenId);

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        unchecked {
            //Limited in constructor
            _nextTokenId = tokenId + 1;
        }
    }

    function safeMintBatched(address to, string[] memory uri) external virtual onlyOwner {
        uint256 size = uri.length;
        require(size > 0);

        uint256 firstTokenId = _nextTokenId;
        uint256 nextTokenId = firstTokenId + size;

        //nextTokenId is not minted. Can be equal to supplyLimit
        require(nextTokenId <= _supplyLimit, ExceedsSupplyLimit(_supplyLimit, nextTokenId - 1));

        for (uint256 i = firstTokenId; i < nextTokenId; i++) {
            _safeMint(to, i);
            _setTokenURI(i, uri[i]);
        }

        _nextTokenId = nextTokenId;
    }

    function _requireMintable(uint256 tokenId) internal view virtual {
        require(tokenId < _supplyLimit, ExceedsSupplyLimit(_supplyLimit, tokenId));
    }

    /*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
            Boilerplate overrides
    -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}
