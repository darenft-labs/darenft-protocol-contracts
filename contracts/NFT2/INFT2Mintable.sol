

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;


interface INFT2Mintable {
      function safeMint(
        address to,
        uint256 tokenId,
        string memory uri,

        uint256 nonce,
        bytes memory verifierSignature
    ) external payable;

    function safeMintAndData(
        address to,
        uint256 tokenId,
        string memory uri,
        uint96 feeNumerator,

        uint256 nonce,
        bytes memory verifierSignature
    ) external payable;

    function safeMintBatch(
        address[] calldata tos,
        uint256[] calldata tokenIds,
        string[] memory uris,
        uint96[] calldata feeNumerators,

        uint256[] calldata nonces,
        bytes[] memory verifierSignatures
    ) external payable;
}