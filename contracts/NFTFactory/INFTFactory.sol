// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface INFTFactory {
    event NFT2Created(
        address indexed contractDeployed,
        address indexed provider,
        address logic,
        string tokenName,
        string symbol
    );

    event NFT2DerivativeCreated(
        address indexed contractDeployed,
        address indexed token,
        uint256 tokenId,
        address logic,
        string tokenName,
        string symbol
    );

    event NFT2DerivativeMinted(
        address indexed to,
        address indexed provider,
        address nft2Token,
        uint256 nft2TokenId,
        address nft2DerivativeToken,
        uint256 nft2DerivativeTokenId
    );
}
