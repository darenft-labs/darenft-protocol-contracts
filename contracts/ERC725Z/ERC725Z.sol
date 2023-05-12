// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

// interfaces
import "./IERC725Z.sol";

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

// modules
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract ERC725Z is ERC165Upgradeable, AccessControlUpgradeable, IERC725Z {

    bytes32 public constant METADATA_ROLE = keccak256("METADATA_ROLE");

    /**
     * @dev Map the dataKeys to their dataValues
     */
    mapping(uint256 => mapping(bytes32 => bytes)) internal store;

    function __ERC725Z_init(
        address admin
    ) internal onlyInitializing {
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __ERC725Z_init_unchained(admin);
    }

    function __ERC725Z_init_unchained(
        address admin
    ) internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(METADATA_ROLE, admin);
    }

    /* Public functions */
    /**
     * @inheritdoc IERC725Z
     */
    function getData(
        uint256 tokenId,
        bytes32 dataKey
    ) public view virtual override returns (bytes memory dataValue) {
        dataValue = _getData(tokenId, dataKey);
    }

    /**
     * @inheritdoc IERC725Z
     */
    function getData(
        uint256 tokenId,
        bytes32[] memory dataKeys
    ) public view virtual override returns (bytes[] memory dataValues) {
        dataValues = new bytes[](dataKeys.length);

        for (uint256 i = 0; i < dataKeys.length; i = _uncheckedIncrement(i)) {
            dataValues[i] = _getData(tokenId, dataKeys[i]);
        }

        return dataValues;
    }

    /**
     * @inheritdoc IERC725Z
     */
    function setData(
        uint256 tokenId,
        bytes32 dataKey,
        bytes memory dataValue
    ) public virtual override onlyRole(METADATA_ROLE) {
        _setData(tokenId, dataKey, dataValue);
    }

    /**
     * @inheritdoc IERC725Z
     */
    function setData(
        uint256 tokenId,
        bytes32[] memory dataKeys,
        bytes[] memory dataValues
    ) public virtual override onlyRole(METADATA_ROLE) {
        require(
            dataKeys.length == dataValues.length,
            "Keys length not equal to values length"
        );
        for (uint256 i = 0; i < dataKeys.length; i = _uncheckedIncrement(i)) {
            _setData(tokenId, dataKeys[i], dataValues[i]);
        }
    }

    /* Internal functions */

    function _getData(
        uint256 tokenId,
        bytes32 dataKey
    ) internal view virtual returns (bytes memory dataValue) {
        return store[tokenId][dataKey];
    }

    function _setData(
        uint256 tokenId,
        bytes32 dataKey,
        bytes memory dataValue
    ) internal virtual {
        store[tokenId][dataKey] = dataValue;
        emit DataChanged(tokenId, dataKey, dataValue);
    }

    /**
     * @dev Will return unchecked incremented uint256
     *      can be used to save gas when iterating over loops
     */
    function _uncheckedIncrement(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

    /* Overrides functions */

    /**
     * @inheritdoc ERC165Upgradeable
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC725Z).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}
