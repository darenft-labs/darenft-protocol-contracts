// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import {INFT2Core} from "./INFT2Core.sol";

import "../ERC725Z/ERC725Z.sol";

import {Royalty} from "../Royalty/Royalty.sol";

import "../utils/universal-receiver/UniversalReceiverUtils.sol";
import "../utils/universal-receiver/IUniversaleReceiver.sol";


import "./constants.sol";

import "./NFT2MetadataURL.sol";
import "../utils/pausable/PausableController.sol";


contract NFT2Core is
    Initializable,
    PausableController,
    INFT2Core,
    NFT2MetadataURL,
    Royalty
{
    using ERC165CheckerUpgradeable for address;
    using UniversalReceiverUtils for address;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ROYALTY_ROLE = keccak256("ROYALTY_ROLE");

    address public contractOwner;
    address public tokenMinter;

    modifier onlyOwnerAndCreator(uint256 tokenId) {
        address executor = _msgSender();
        address creator = getTokenCreator(tokenId);

        require(
            ownerOf(tokenId) == executor && creator == executor,
            "NFT2: Account is not both owner and creator of token id"
        );
        _;
    }

    function __NFT2Core_init(
        string memory tokenName,
        string memory symbol,
        address owner,
        address minter,
        address metadataAdmin
    ) internal onlyInitializing {
        __AccessControl_init_unchained();
        __ERC725Z_init_unchained(metadataAdmin);
        __ERC725Z2_init_unchained(metadataAdmin);
        __ERC721_init_unchained(tokenName, symbol);

        address defaultAdmin = _msgSender();
        if (owner != address(0)) {
            defaultAdmin = owner;
        }

        __NFT2Core_init_unchained(
            minter,
            defaultAdmin
        );
    }

    function __NFT2Core_init_unchained(
        address minter,
        address defaultAdmin
    ) internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, minter);

        contractOwner = defaultAdmin;
        tokenMinter = minter;
    }

    function _setData( uint256 tokenId,
        bytes32 dataKey,
        bytes memory dataValue) internal virtual override {
        super._setData(tokenId, dataKey, dataValue);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(IERC721MetadataUpgradeable, NFT2MetadataURL)
        returns (string memory)
    {
        return NFT2MetadataURL.tokenURI(tokenId);
    }

    function getContractCreator() public view returns (address) {
        return contractOwner;
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        string memory uri,
        address royaltyReceiver,
        uint96 feeNumerator
    ) internal virtual {
        super._safeMint(to, tokenId);
        super._setTokenURI(tokenId, uri);
        super._setRoyalties(tokenId, royaltyReceiver, feeNumerator);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    )
        internal
        virtual
        override(ERC721Upgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable)
    {
        super._burn(tokenId);

        if (
            tokenMinter.supportsInterface(type(IUniversaleReceiver).interfaceId)
        ) {
            tokenMinter.callUniversalReceiverWithCallerInfos(
                DERIVATIVE_NFT_BURN_EVENT,
                abi.encode(address(this), tokenId),
                getTokenCreator(tokenId)
            );
        }
    }

    function burn(uint256 tokenId) public payable virtual {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        _burn(tokenId);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return super._exists(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, NFT2MetadataURL, PausableController, Royalty)     
        returns (bool)
    {
        return ERC721Upgradeable.supportsInterface(interfaceId) 
        || Royalty.supportsInterface(interfaceId)
        || NFT2MetadataURL.supportsInterface(interfaceId) 
        || PausableController.supportsInterface(interfaceId) 
        || type(INFT2Core).interfaceId == interfaceId
        || super.supportsInterface(interfaceId);
    }
}
