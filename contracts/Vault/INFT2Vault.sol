// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface INFT2Vault {
    event NFTLocked(address from, address nft2Token, uint256 nft2TokenId);

    event NFTReleased(address to, address nft2Token, uint256 nft2TokenId);

    function isLockedNFT2(address token, uint256 tokenId)
        external
        view
        returns (bool);

    function getOwnerOfLockedNFT2(address token, uint256 tokenId)
        external
        view
        returns (address);

    function lockNFT2(
        address from,
        address nft2Token,
        uint256 nft2TokenId
    ) external;

    function releaseNFT2(
        address nft2Token,
        uint256 nft2TokenId,
        address from,
        address to
    ) external;

    function setDerivativeNFT2ForNFT2(
        address nft2Token,
        uint256 nft2TokenId,
        address provider,
        address nft2DerivativeToken,
        uint256 nft2DerivativeTokenId
    ) external;

    function removeDerivativeNFT2(
        address nft2Token,
        uint256 nft2TokenId,
        address provider,
        address nft2DerivativeToken
    ) external;
}
