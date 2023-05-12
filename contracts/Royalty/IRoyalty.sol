// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IRoyalty is IERC165Upgradeable {
    event RoyaltyChanged(
        uint256 indexed tokenId,
        address indexed creator,
        uint96 feeNumerator
    );

    event RoyaltyClaimed(address token, address receiver, uint256 amount);

    function getTokenCreator(uint256 tokenId) external view returns (address);

    function claimRoyalty(address[] calldata tokens) external payable;

    function feeRoyaltyDenominator() external returns (uint96);

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}