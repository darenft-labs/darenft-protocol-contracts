// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAggregatable {
    struct Call {
        address target;
        bytes data;
    }
}
