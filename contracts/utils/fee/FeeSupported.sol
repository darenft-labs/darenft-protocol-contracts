// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./IFeeController.sol";

abstract contract FeeSupported {
    function feeController() public view virtual returns (address);

    function applySystemFee(bytes32 method) internal virtual returns (uint256) {
        return applySystemFee(method, 1);
    }

    function applySystemFee(bytes32 method, uint256 quantity)
        internal
        virtual
        returns (uint256)
    {
        // ignore fee
        if (feeController() == address(0)) return 0;

        uint256 minFee = IFeeController(feeController()).feeOf(method) *
            quantity;

        if (minFee == 0) return 0;

        if (minFee > msg.value) revert("not enough");

        IFeeController(feeController()).deposit{value: msg.value}();
        return minFee;
    }
}
