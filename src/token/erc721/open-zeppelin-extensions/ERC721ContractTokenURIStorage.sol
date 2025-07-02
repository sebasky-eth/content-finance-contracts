// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0

pragma solidity ^0.8.30;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IERC7572} from "../../common/IERC7572.sol";

/**
 * @title Extension for ERC721 (for OpenZeppelin base) that add (OZ) tokenURIStorage and contractURIStorage that share baseURI
 * @author Sebasky (https://github.com/sebasky-eth)
 */
abstract contract ERC721ContractTokenURIStorage is ERC721URIStorage, Ownable, IERC7572 {
    string private _contractURI;

    constructor(string memory contractUri) {
        _setContractURI(contractUri);
    }

    function contractURI() external view virtual returns (string memory) {
        string memory uri = _contractURI;
        if (bytes(uri).length == 0) {
            return "";
        }

        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return uri;
        }

        return string.concat(base, uri);
    }

    function setContractURI(string memory cidOfContractURI) external virtual onlyOwner {
        _setContractURI(cidOfContractURI);
        emit ContractURIUpdated();
    }

    function _setContractURI(string memory cidOfContractURI) internal virtual {
        _contractURI = cidOfContractURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
