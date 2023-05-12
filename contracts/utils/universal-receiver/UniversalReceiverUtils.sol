// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

// libraries
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {IUniversaleReceiver} from "./IUniversaleReceiver.sol";

library UniversalReceiverUtils {
    function callUniversalReceiverWithCallerInfos(
        address universalReceiverDelegate,
        bytes32 typeId,
        bytes memory receivedData,
        address msgSender
    ) internal {
        bytes memory callData = abi.encodePacked(
            abi.encodeWithSelector(
                IUniversaleReceiver.universalReceiver.selector,
                typeId,
                receivedData
            ),
            msgSender
        );

        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory result) = universalReceiverDelegate.call(
            callData
        );
        AddressUpgradeable.verifyCallResult(
            success,
            result,
            "Call to universalReceiver failed"
        );
    }
}
