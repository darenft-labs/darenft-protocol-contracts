// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./INFT2Vault.sol";
import "../TokenTransferProxy/ITokenTransferProxy.sol";

contract NFT2Vault is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    IERC721Receiver,
    INFT2Vault
{
    using AddressUpgradeable for address;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");

    mapping(address => mapping(uint256 => address)) lockedNft2s;

    mapping(address => mapping(uint256 => uint256)) nft2DerivativeCounts;
    mapping(address => mapping(uint256 => mapping(address => mapping(address => uint256)))) nft2Derivatives;

    ITokenTransferProxy public tokenTransferProxy;

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

    function isLockedNFT2(address token, uint256 tokenId)
        public
        view
        returns (bool)
    {
        if (lockedNft2s[token][tokenId] != address(0)) {
            return true;
        } else {
            return false;
        }
    }

    function getOwnerOfLockedNFT2(address nft2Token, uint256 nft2TokenId)
        public
        view
        returns (address)
    {
        return lockedNft2s[nft2Token][nft2TokenId];
    }

    function lockNFT2(
        address from,
        address nft2Token,
        uint256 nft2TokenId
    ) public whenNotPaused onlyRole(VAULT_ROLE) {
        require(
            IERC721Upgradeable(nft2Token).ownerOf(nft2TokenId) == from,
            "NFT2Vault: Account is not owner of this nft2"
        );

        tokenTransferProxy.nft721TransferFrom(
            nft2Token,
            from,
            address(this),
            nft2TokenId
        );

        lockedNft2s[nft2Token][nft2TokenId] = from;

        emit NFTLocked(from, nft2Token, nft2TokenId);
    }

    function releaseNFT2(
        address nft2Token,
        uint256 nft2TokenId,
        address from,
        address to
    ) public whenNotPaused onlyRole(VAULT_ROLE) {
        require(
            nft2DerivativeCounts[nft2Token][nft2TokenId] == 0,
            "NFT2Vault: More than 1 derivative nft token from this nft2"
        );
        require(
            lockedNft2s[nft2Token][nft2TokenId] == from,
            "NFT2Vault: Account is not owner of nft before being locked"
        );

        if (
            !IERC721Upgradeable(nft2Token).isApprovedForAll(
                address(this),
                address(tokenTransferProxy)
            )
        ) {
            IERC721Upgradeable(nft2Token).setApprovalForAll(
                address(tokenTransferProxy),
                true
            );
        }

        tokenTransferProxy.nft721TransferFrom(
            nft2Token,
            address(this),
            to,
            nft2TokenId
        );
        lockedNft2s[nft2Token][nft2TokenId] = address(0);

        emit NFTReleased(to, nft2Token, nft2TokenId);
    }

    function setDerivativeNFT2ForNFT2(
        address nft2Token,
        uint256 nft2TokenId,
        address provider,
        address nft2DerivativeToken,
        uint256 nft2DerivativeTokenId
    ) public whenNotPaused onlyRole(VAULT_ROLE) {
        nft2DerivativeCounts[nft2Token][nft2TokenId] += 1;
        nft2Derivatives[nft2Token][nft2TokenId][provider][
            nft2DerivativeToken
        ] = nft2DerivativeTokenId;
    }

    function removeDerivativeNFT2(
        address nft2Token,
        uint256 nft2TokenId,
        address provider,
        address nft2DerivativeToken
    ) public onlyRole(VAULT_ROLE) {
        require(
            nft2Derivatives[nft2Token][nft2TokenId][provider][
                nft2DerivativeToken
            ] != 0,
            "NFT2Vault: Already remove this derivative nft token"
        );
        nft2DerivativeCounts[nft2Token][nft2TokenId] -= 1;
        nft2Derivatives[nft2Token][nft2TokenId][provider][
            nft2DerivativeToken
        ] = 0;
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
