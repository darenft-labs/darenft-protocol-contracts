// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ITimeHelper {
    function getOpeningTime(uint256 tokenId) external returns (uint256);

    function getClosingTime(uint256 tokenId) external returns (uint256);

    function isOpen(uint256 tokenId) external returns (bool);

    function hasClosed(uint256 tokenId) external returns (bool);
}
