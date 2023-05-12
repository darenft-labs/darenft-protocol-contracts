// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

import "./IDataSourceRegistry.sol";

contract DataSourceRegistry is IDataSourceRegistry, ERC165Upgradeable {

    mapping(address => bool) internal _dataSources;

    function isDataSource(
        address candidate
    ) external view override returns (bool) {
      return _dataSources[candidate];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
      return type(IDataSourceRegistry).interfaceId == interfaceId ||
        super.supportsInterface(interfaceId);
    }
}