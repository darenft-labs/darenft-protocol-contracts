// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IMarketplaceVault {
    function ownerOf(address tokenAddress, uint256 tokenId)
        external
        returns (address);

    function deposit(
        address from,
        address token,
        uint256 tokenId
    ) external;

    function withdraw(
        address to,
        address token,
        uint256 tokenId
    ) external;
}
