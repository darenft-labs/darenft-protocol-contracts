// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IOriginalNFTVault {
    function isLockedNFT(address token, uint256 tokenId)
        external
        returns (bool);

    function lockOriginalNFT(
        address from,
        address token,
        uint256 tokenId,
        address nft2Token,
        uint256 nft2TokenId
    ) external;

    function releaseOriginalNFT(
        address token,
        uint256 tokenId,
        address to
    ) external;
}
