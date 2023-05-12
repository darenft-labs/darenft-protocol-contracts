// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.9;


import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "solidity-bytes-utils/contracts/BytesLib.sol";
import "../ERC725Z/ERC725Z2.sol";
import "../interfaces/IERC4096Upgradeable.sol";

import "./constants.sol";


abstract contract NFT2MetadataURL is IERC721MetadataUpgradeable, IERC4096Upgradeable, ERC725Z2, ERC721Upgradeable {

    using StringsUpgradeable for bytes;

    /**
     * @dev See {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, ERC725Z2, IERC165Upgradeable) returns (bool) {
        return type(IERC721MetadataUpgradeable).interfaceId == interfaceId 
        || type(IERC4096Upgradeable).interfaceId == interfaceId
        || ERC721Upgradeable.supportsInterface(interfaceId)
        || ERC725Z.supportsInterface(interfaceId);
    }

    /*
     * @inheritdoc ILSP8CompatibleERC721
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721Upgradeable, IERC721MetadataUpgradeable) returns (string memory) {
        bytes memory data = _getData(tokenId, DNFT_METADATA_KEY);

        if (data.length == 0) {
            return "";
        }

        return string(data);
    }

    function _setData(
        uint256 tokenId,
        bytes32 dataKey,
        bytes memory dataValue
    ) internal virtual override {
        super._setData(tokenId, dataKey, dataValue);

        // emit Update event
        if (dataKey == DNFT_METADATA_KEY) {
            emit MetadataUpdate(tokenId);
        }
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Emits {MetadataUpdate}.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _setData(tokenId, DNFT_METADATA_KEY, abi.encodePacked(_tokenURI));
    }
}
