// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IDerivativeNFT2 {
    function getOriginalToken() external view returns (address, uint256);

    function getTokenDetail(
        uint256 tokenId
    ) external view returns (address, address, uint256);

    function getCurrentToken(address provider) external view returns (uint256);

    function safeMint(
        address to,
        string memory uri,
        address provider,

        uint256 nonce,
        bytes memory verifierSignature
    ) external payable returns (uint256);

    function safeMintAndSetInfo(
        address to,
        string memory uri,
        address provider,
        uint256 openTime,
        uint256 closingTime,
        uint96 feeNumerator,

        uint256 nonce,
        bytes memory verifierSignature
    ) external payable returns (uint256);

    function setRoyalties(uint256 tokenId, uint96 feeNumerator) external;

    function setTime(
        uint256 tokenId,
        uint256 openTime,
        uint256 closingTime
    ) external;
}
