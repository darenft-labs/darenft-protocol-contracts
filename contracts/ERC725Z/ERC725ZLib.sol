// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;
import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";

/**
 * deprecated 
 */
library ERC725ZLib {
    function buildDataKey(
        address namespace,
        bool isStandard,
        string memory name
    ) internal pure returns (bytes32) {
        bytes32 res;
        bytes4 key = bytes4(keccak256(abi.encode(name)));
        // <20bytes game_identity><4bytes key><1 bytes flag><reserver>
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, namespace) // game_identity
            mstore(add(ptr, 20), key)
            mstore(add(ptr, 21), isStandard)
            mstore(add(ptr, 22), 0x0000000) // reverse key

            res := mload(ptr)
        }

        return res;
    }
}
