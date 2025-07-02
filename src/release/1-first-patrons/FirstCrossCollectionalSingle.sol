// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.30;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC721, IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {ERC721PairedBinderPrelaunched} from
    "../../token/erc721/open-zeppelin-extensions/ERC721PairedBinderPrelaunched.sol";
import {IERC721MultipairedBinder} from "../../token/erc721/IERC721MultipairedBinder.sol";
import {ERC721ContractTokenURIStorage} from
    "../../token/erc721/open-zeppelin-extensions/ERC721ContractTokenURIStorage.sol";
import {ERC721DynamicallyMintable} from "../../token/erc721/open-zeppelin-extensions/ERC721DynamicallyMintable.sol";
import {GroupedTokenMapper} from "../../token/utils/GroupedTokenMapper.sol";

/**
 * @title Contract used for 'FirstPatrons. Small collection (like album) that shares tokens with "main collection" (like Music Patrons).
 * @dev Bindable collection with small initial release ('firstTokensURI') and token-independent static uri.
 * Require deployment of {BinderFactory} beforehand for deterministic
 * @author
 */
contract FirstCrossCollectionalSingle is
    ERC721,
    Ownable,
    ERC2981,
    ERC721ContractTokenURIStorage,
    ERC721PairedBinderPrelaunched,
    ERC721DynamicallyMintable
{
    error SupplyLimitTooBig(uint256 limit, uint256 maximumLimit);

    /**
     * @param name - collection name.
     * @param symbol - collection symbol.
     * @param cidOfContractURI - "ipfs://[cid]" of contractURI.
     * @param initialOwner - contract owner {Ownable}.
     * @param royaltyReceiver - receiver of royality {ERC2981}.
     * @param feeNumerator - royality information in basis points (1 basis point = 0.01%).
     * @param coreBinder - cross-collectional core.
     * @param groupIdBitWidth - how many bits groupId will have in coreBinder
     * @param maximumSupply - maximum amount of tokens in collection. If 0: will be calculated. Can be decreased after deployment with {changeSupplyLimit}.
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory cidOfContractURI,
        address initialOwner,
        address royaltyReceiver,
        uint96 feeNumerator,
        IERC721MultipairedBinder coreBinder,
        uint256 groupId,
        uint256 groupIdBitWidth,
        uint256 maximumSupply
    )
        ERC721(name, symbol)
        Ownable(initialOwner)
        ERC721PairedBinderPrelaunched(coreBinder, groupId, groupIdBitWidth)
        ERC721ContractTokenURIStorage(cidOfContractURI)
        ERC721DynamicallyMintable(maximumSupply)
    {
        _verifyMaximumSupply(maximumSupply);
        _setDefaultRoyalty(royaltyReceiver, feeNumerator);
    }

    function _verifyMaximumSupply(uint256 maximumSupply) internal view {
        require(
            GroupedTokenMapper.checkTokenForMapping(_tokenIdBitWidth, maximumSupply),
            SupplyLimitTooBig(maximumSupply, GroupedTokenMapper.maximumTokenForMapping(_tokenIdBitWidth))
        );
    }

    /*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
            Boilerplate overrides
    -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721ContractTokenURIStorage, ERC721PairedBinderPrelaunched, ERC721DynamicallyMintable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721ContractTokenURIStorage, ERC721DynamicallyMintable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721, ERC721PairedBinderPrelaunched, IERC721)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, ERC721PairedBinderPrelaunched, IERC721)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
            Rest
    -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*/

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }
}
