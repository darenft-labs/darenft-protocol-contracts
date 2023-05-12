// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IUniversaleReceiver {
    function universalReceiver(bytes32 typeId, bytes calldata receivedData)
        external;
}
