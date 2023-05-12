// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IExecuteRelayable {
    function getNonce(address from, uint256 channelId)
        external
        view
        returns (uint256);

    function executeRelayCall(
        bytes calldata rootSignature_,
        bytes calldata signature_,
        uint256 nonce_,
        address target_,
        bytes calldata data_
    ) external returns (bytes memory);
}
