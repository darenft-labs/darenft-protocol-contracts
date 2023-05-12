


// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

interface IDataSourceRegistry {
  function isDataSource(address candidate) external view returns(bool);
}