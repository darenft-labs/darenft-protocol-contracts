// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

import "./ITimeHelper.sol";

/**
 * @title TimeHelper
 * @dev Helper for accepting contributions only within a time frame.
 */
//  => abstract contract
contract TimeHelper is ERC165Upgradeable, ITimeHelper {
    struct Timeframe {
        uint256 openingTime;
        uint256 closingTime;
    }

    mapping(uint256 => Timeframe) private tokenPeriods;

    event TimeSet(
        uint256 indexed tokenId,
        uint256 openingTime,
        uint256 closingTime
    );

    /**
     * @dev Reverts if not in time range.
     */
    modifier onlyWhileOpen(uint256 tokenId) {
        require(isOpen(tokenId), "TimeHelper: not open");
        _;
    }

    /**
     * @return the opening time.
     */
    function getOpeningTime(uint256 tokenId) public view returns (uint256) {
        return tokenPeriods[tokenId].openingTime;
    }

    /**
     * @return the closing time.
     */
    function getClosingTime(uint256 tokenId) public view returns (uint256) {
        return tokenPeriods[tokenId].closingTime;
    }

    /**
     * @return true if the is open, false otherwise.
     */
    function isOpen(uint256 tokenId) public view returns (bool) {
        return
            tokenPeriods[tokenId].openingTime > 0 &&
            block.timestamp >= tokenPeriods[tokenId].openingTime &&
            block.timestamp <= tokenPeriods[tokenId].closingTime;
    }

    /**
     * @dev Checks whether the period in which is open has already elapsed.
     * @return Whether period has elapsed
     */
    function hasClosed(uint256 tokenId) public view returns (bool) {
        return
            tokenPeriods[tokenId].openingTime == 0 ||
            block.timestamp > tokenPeriods[tokenId].closingTime;
    }

    function _setTime(
        uint256 tokenId,
        uint256 openingTime,
        uint256 closingTime
    ) internal {
        // require(openingTime > 0, "TimeHelper: open time cannot be 0");

        if (openingTime > 0) {
            require(
                closingTime > openingTime,
                "TimeHelper: closing time is before opening time"
            );
        }

        tokenPeriods[tokenId] = Timeframe({
            openingTime: openingTime,
            closingTime: closingTime
        });

        emit TimeSet(tokenId, openingTime, closingTime);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(ITimeHelper).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}
