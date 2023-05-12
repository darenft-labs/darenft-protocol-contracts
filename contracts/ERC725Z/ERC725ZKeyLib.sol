// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;
import {IERC725Y} from "@erc725/smart-contracts/contracts/interfaces/IERC725Y.sol";

/**
 * deprecated 
 */
library ERC725ZKeyLib {
    function namespace(bytes32 key) internal pure returns(address) {
        return address(bytes20(key));
    }
}
