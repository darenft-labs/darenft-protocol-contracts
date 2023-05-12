// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MiddlewareForwarder is Initializable, ContextUpgradeable {
    mapping(address => bool) private trustedForwarders;

    function __MiddlewareForwarderContext_init() internal onlyInitializing {
        __Context_init_unchained();
        __MiddlewareForwarderContext_init_unchained();
    }

    function __MiddlewareForwarderContext_init_unchained()
        internal
        onlyInitializing
    {}

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return trustedForwarders[forwarder];
    }

    function setTrustedForwarder(address forwarder, bool x) internal {
        trustedForwarders[forwarder] = x;
    }

    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    uint256[49] private __gap;
}
