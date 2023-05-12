// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./IPausableController.sol";

contract PausableController is IPausableController, PausableUpgradeable, AccessControlUpgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    function __PausableController_init(
      address admin_
    ) internal onlyInitializing {
        __Pausable_init_unchained();
        __AccessControl_init_unchained();
        __PausableController_init_unchained(admin_);
    }

    function __PausableController_init_unchained(
      address admin_
    ) internal onlyInitializing {
      // setup role
      _grantRole(PAUSER_ROLE, admin_);
    }

    function pause() public override onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public override onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return type(IPausableController).interfaceId == interfaceId || super.supportsInterface(interfaceId);
    }
}
