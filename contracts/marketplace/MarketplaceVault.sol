// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// modules
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

// interfaces
import "./IMarketplaceVault.sol";
import "../TokenTransferProxy/ITokenTransferProxy.sol";

// libraries

// extensions

contract MarketplaceVault is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    IERC721Receiver,
    IMarketplaceVault
{
    using AddressUpgradeable for address;
    using ERC165CheckerUpgradeable for address;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    event Deposit(uint256 tokenId, address token, address owner);

    event Withdraw(uint256 tokenId, address token, address owner);

    ITokenTransferProxy public tokenTransferProxy;

    mapping(address => mapping(uint256 => address)) tokenOwners;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner, address tokenTransferProxy_)
        public
        initializer
    {
        __Pausable_init();
        __AccessControl_init_unchained();

        address defaultAdmin = _msgSender();
        if (owner != address(0)) {
            defaultAdmin = owner;
        }

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, defaultAdmin);

        tokenTransferProxy = ITokenTransferProxy(tokenTransferProxy_);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function ownerOf(address tokenAddress, uint256 tokenId)
        public
        view
        returns (address)
    {
        return tokenOwners[tokenAddress][tokenId];
    }

    function deposit(
        address from,
        address token,
        uint256 tokenId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        address owner = IERC721(token).ownerOf(tokenId);

        require(
            owner == from,
            "MarketplaceVault: from address is not owner of nft"
        );

        tokenTransferProxy.nft721TransferFrom(
            token,
            from,
            address(this),
            tokenId
        );
        tokenOwners[token][tokenId] = owner;

        emit Deposit(tokenId, token, owner);
    }

    function withdraw(
        address to,
        address token,
        uint256 tokenId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        address owner = tokenOwners[token][tokenId];

        if (
            !IERC721(token).isApprovedForAll(
                address(this),
                address(tokenTransferProxy)
            )
        ) {
            IERC721(token).setApprovalForAll(address(tokenTransferProxy), true);
        }

        tokenTransferProxy.nft721TransferFrom(
            token,
            address(this),
            to,
            tokenId
        );
        delete tokenOwners[token][tokenId];

        emit Withdraw(tokenId, token, owner);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
