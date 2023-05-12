// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.9;

interface IFeeSupported {
    function feeController() external view returns (address);

    function setFeeController(address feeController_) external;
}
