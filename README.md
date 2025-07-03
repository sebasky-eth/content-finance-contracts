# Contracts for Content Finance

Still expanded contracts and protocols for content tokenization.

## IBindableToken

Cross-collectional tokens. Good for small collections that can belong to bigger one. For example: *Patrons of artist* combine tracks from all albums {IERC721MultipairedBinder}. [Smaller collection](https://opensea.io/collection/first-patrons) {IERC721PairedBinder} has very small supply, but don't dissolve symbolic capital by sharing belonging with front-runner.

Additional advantages: you can postpone release of main collection to work on additional functionalities. I have big plans for it: tokenURI customizable by owners (HTML based URI), integrations with identity providers (ENS profile), commercially correct renting system and more.

For collections that are connected with core {IERC721CoreBinder}, CREATE3 can be utilized to validate binding mechanism and provide collections for dApps. And that is how I could release album collection before main one.

## Roadmap

1. Create explanation how to create collections by using already deployed helpers. ✅
2. Improve comments, create visual explanations of IBindableToken protocol.
3. Implementation of RetroactiveApprovals, Commercialy correct renting system, token customization system.
4. BitfieldERC721 - implementation of gas efficient collections with supply limit.
5. Implementation of IERC721MultipairedBinder in BitfieldERC721.
6. New type of token (that utilize IERC1155 to be recognized by dApps). Used as interface for interactions with smart contracts without need to use browser extensions.
7. Nicely looking frontend for music tokenization.
8. Supporters and Sponsors Ecosystem that optimize monetisation of symbolic capital and prevent representatives to rug pull their fans.

## Usage (Forge)

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Deploying Cross-collectionall smaller collection

#### Infrastructure:

A. Factory that deploys all collections.
B. Core collection that store all tokens (could be deployed later).
N. Many smaller collections.

"tokenId" in core collection is created from "[tokenIdInGroup][groupId]".

#### Why you could deploy smaller collection before core was created?

ERC721PairedBinderPrelaunched act independently. When core will be released, it will unlock binding mechanism and call it whatever transfer is made, so it can mirror transfer (by casting event). But for now it is normally functional collection.

So you can release very small collection now and expand it with core when next item arrives for group (album for discography, novel for series, etc.).

#### Deploying

##### 1. BinderFactoryDeployer

Call [deployIncrementalOwnableFactory (0x276c5101)](https://basescan.org/address/0x59b9f15621fa999fcb305dc7ee65f99d2ee428ac#writeContract#F2) with name of core collection and address of initial owner.

Name is not that important (but it gives you more predictability for future multi-collectional releases, if you want to use this contract again).

Result: creating new smart contract: IncrementalOwnableFactory.

##### 2. CrossCollectionPrerelease

Call [firstCrossCollectionalSingleInitCode](https://basescan.org/address/0x1d4b37e44131b6b95181b21c7700a307d5a8d393#readContract#F1)
It has many arguments and creates init code for small collection. Save result for step 3 and 4.

There is non-standard argument: "groupIdBitWidth". What it does?
Core collection will have "tokenId" bit size: "[tokenIdBitWidth][groupIdBitWidth]".
GroupIdBitWidth reduce maximum amount of groups. I set it to 9, so there could be 510 groups in my core collection (2^9 - 2).
Reduction is good for gas, because more information can be stored together with "tokenId".
If you want more groups, just use 16 bits (65534 max). Or even 128 (practically unlimited).

##### 3. IncrementalOwnableFactory

Call [deploy (0x00774360)](https://basescan.org/address/0x8631292208dc3c1a3e3935b312e602a42bc662e0#writeContract#F1)
Pass init code from 2.

##### 4.A Verify your contract to be able to mint tokens from etherscan

Compare bycode from 2. with bycode from initial transaction. Additional characters will be used as encoded constructor arguments.

##### 4.B Download project and deploy from IDE

Project is wrote for foundry (developing/testing). But fore deploying I recommend Remix-IDE (more comfortable security - metamask/rabby/etc). Change imports if necessary.

From:

``` solidity
import {CREATE3} from "solady/utils/CREATE3.sol";
```

To:

``` solidity
import {CREATE3} from "solady/src/utils/CREATE3.sol";
```
