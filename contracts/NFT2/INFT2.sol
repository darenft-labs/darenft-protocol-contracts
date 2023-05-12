// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface INFT2 {
    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri,
        uint256 nonce,
        bytes memory verifierSignature
    ) external payable;
}

interface INFT2AutoID {
    function safeMint(
        address to, 
        string memory uri,
        uint256 nonce,
        bytes memory verifierSignature
    ) external payable;
}
