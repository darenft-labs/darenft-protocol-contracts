

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IRoyaltyUpdateable is IERC165Upgradeable {
  function setRoyalties(uint256 tokenId, address receiver, uint96 feeNumerator) external;
}