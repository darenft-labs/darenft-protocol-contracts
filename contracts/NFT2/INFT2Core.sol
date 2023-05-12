// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface INFT2Core is IERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    function getContractCreator() external view returns (address);

    function burn(uint256 tokenId) external payable;

    function exists(uint256 tokenId) external view returns (bool);
}
