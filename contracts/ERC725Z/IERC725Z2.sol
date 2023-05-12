// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

// interfaces

import "./IERC725Z.sol";

/**
 * @title The interface for ERC725Z2 General data key/value store for ERC721, support verifier
 * @dev ERC725YZ provides the ability to set arbitrary data key/value pairs that can be changed over time
 * It is intended to standardise certain data key/value pairs to allow automated read and writes
 * from/to the contract storage
 */
interface IERC725Z2 is IERC725Z {

    function getNonce(address signer, uint128 channelId) external view returns(uint256);
    
    function verifier() external view returns(address);

    /**
     * @param dataKey The data key which data value is set
     * @param dataValue The data value to set
     * @dev Emits a {DataChanged} event.
     * SHOULD only be callable by the owner of the contract set via ERC173
     * Emits a {DataChanged} event.
     */
    function setData(
        uint256 tokenId,
        bytes32 dataKey,
        bytes memory dataValue,

        uint256 nonce,

        address source,
        bytes memory sourceSignature,
        bytes memory verifierSignature
    ) external payable;

    /**
     * @param dataKeys The array of data keys for values to set
     * @param dataValues The array of values to set
     * @dev Sets array of data for multiple given `dataKeys`
     * SHOULD only be callable by the owner of the contract set via ERC173
     *
     * Emits a {DataChanged} event.
     */
    function setData(
        uint256 tokenId,
        bytes32[] memory dataKeys,
        bytes[] memory dataValues,

        uint256 nonce,

        address source,
        bytes memory sourceSignature,

        bytes memory verifierSignature
    ) external payable;
}
