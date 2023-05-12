// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.9;

interface IFeeController {
    function feeOf(bytes32 method) external view returns (uint256);

    function deposit() external payable;
}
