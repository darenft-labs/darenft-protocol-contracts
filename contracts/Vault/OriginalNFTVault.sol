// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

import {IOriginalNFTVault} from "./IOriginalNFTVault.sol";

contract OriginalNFTVault is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    IOriginalNFTVault
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    struct NFT2Info {
        address token;
        uint256 tokenId;
    }

    mapping(address => mapping(uint256 => NFT2Info)) private nftMappings;

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

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function isLockedNFT(address token, uint256 tokenId)
        public
        view
        returns (bool)
    {
        if (nftMappings[token][tokenId].token != address(0)) {
            return true;
        } else {
            return false;
        }
    }

    function lockOriginalNFT(
        address from,
        address token,
        uint256 tokenId,
        address nft2Token,
        uint256 nft2TokenId
    ) public whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC721(token).transferFrom(from, address(this), tokenId);
        nftMappings[token][tokenId] = NFT2Info({
            token: nft2Token,
            tokenId: nft2TokenId
        });
    }

    function releaseOriginalNFT(
        address token,
        uint256 tokenId,
        address to
    ) public whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC721(token).transferFrom(address(this), to, tokenId);
        delete nftMappings[token][tokenId];
    }
}
