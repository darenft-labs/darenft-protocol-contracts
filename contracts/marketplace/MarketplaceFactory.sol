// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// modules
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// interfaces

// libraries

// extensions

// Pending, we dont use this contract yet
contract MarketplaceFactory is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    using ERC165CheckerUpgradeable for address;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    mapping(address => uint256) nonces;
    mapping(address => mapping(uint256 => address)) providerMarketplaces;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner) public initializer {
        __Pausable_init();
        __AccessControl_init_unchained();

        address defaultAdmin = _msgSender();
        if (owner != address(0)) {
            defaultAdmin = owner;
        }

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, defaultAdmin);
    }

    // function pause() public onlyRole(PAUSER_ROLE) {
    //     _pause();
    // }

    // function unpause() public onlyRole(PAUSER_ROLE) {
    //     _unpause();
    // }

    // function marketplaceOf(address provider_, uint256 nonce)
    //     public
    //     view
    //     returns (address)
    // {
    //     return providerMarketplaces[provider_][nonce];
    // }

    // function getMarketplace(address logic, address provider)
    //     public
    //     view
    //     returns (address, bytes32)
    // {
    //     bytes32 salt_ = keccak256(abi.encode(provider, nonces[provider]));

    //     address newAddress = ClonesUpgradeable.predictDeterministicAddress(
    //         logic,
    //         salt_,
    //         address(this)
    //     );

    //     return (newAddress, salt_);
    // }

    // function _deployMarketplace(
    //     address marketplaceLogic_,
    //     address provider_,
    //     bytes calldata initialCode_
    // ) internal returns (address) {
    //     // non-reentrancy
    //     (address newAddress, bytes32 salt_) = getMarketplace(
    //         marketplaceLogic_,
    //         provider_
    //     );

    //     ClonesUpgradeable.cloneDeterministic(marketplaceLogic_, salt_);

    //     AddressUpgradeable.functionCallWithValue(
    //         newAddress,
    //         initialCode_,
    //         msg.value
    //     );

    //     providerMarketplaces[provider_][nonces[provider_]] = newAddress;

    //     nonces[provider_] += 1;

    //     return newAddress;
    // }

    // function deployMarketplace(
    //     address marketplaceLogic_,
    //     address provider_,
    //     bytes calldata initialCode_
    // ) public payable onlyRole(DEFAULT_ADMIN_ROLE) {
    //     _deployMarketplace(marketplaceLogic_, provider_, initialCode_);
    // }
}
