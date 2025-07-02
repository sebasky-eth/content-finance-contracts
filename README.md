# Contracts for Content Finance

Still expanded contracts and protocols for content tokenization.

## IBindableToken

Cross-collectional tokens. Good for small collections that can belong to bigger one. For example: *Patrons of artist* combine tracks from all albums {IERC721MultipairedBinder}. [Smaller collection](https://opensea.io/collection/first-patrons) {IERC721PairedBinder} has very small supply, but don't dissolve symbolic capital by sharing belonging with front-runner.

Additional advantages: you can postpone release of main collection to work on additional functionalities. I have big plans for it: tokenURI customizable by owners (HTML based URI), integrations with identity providers (ENS profile), commercially correct renting system and more.

For collections that are connected with core {IERC721CoreBinder}, CREATE3 can be utilized to validate binding mechanism and provide collections for dApps. And that is how I could release album collection before main one.

## Roadmap

1. Create explanation how to create collections by using already deployed helpers.
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