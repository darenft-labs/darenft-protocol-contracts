// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IExecutable {
    function execute(address target_, bytes memory data_)
        external
        returns (bytes memory);
}
