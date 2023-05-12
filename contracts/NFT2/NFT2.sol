// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../utils/fee/FeeSupported.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";


import "./NFT2Core.sol";

import "../utils/fee/IFeeSupported.sol";
import "./INFT2.sol";

import "../ERC725Z/ERC725ZKeyLib.sol";

import "../Royalty/IRoyaltyUpdateable.sol";
import "./INFT2Mintable.sol";

import "../utils/data-source/IDataSourceRegistry.sol";


contract NFT2 is
    Initializable,
    AccessControlUpgradeable,
    NFT2Core,
    INFT2,
    FeeSupported,
    IRoyaltyUpdateable,
    INFT2Mintable
{
    using AddressUpgradeable for address;
    using SignatureCheckerUpgradeable for address;
    using ERC725ZKeyLib for bytes32;
    using ERC165CheckerUpgradeable for address;
    using ECDSAUpgradeable for bytes32;

    address internal _feeController;
    address internal _dataSourceRegistry;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory tokenName,
        string memory symbol,
        address owner,
        address minter,
        address metadataAdmin
    ) public initializer {
        __NFT2_init(tokenName, symbol, owner, minter, metadataAdmin);
    }

    function __NFT2_init_unchained() internal onlyInitializing {}

    function __NFT2_init(
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

        __NFT2Core_init_unchained(minter, defaultAdmin);
    }

    function _validateVerifierForTokenURI(
        uint256 tokenId,
        string memory uri,
        uint256 nonce,
        bytes memory verifierSignature
    ) internal view virtual {
        bytes32 dataHash = generateDataHash(
            nonce,
            tokenId,
            DNFT_METADATA_KEY,
            abi.encode(uri)
        );

        require(verifier() != address(0) 
            && verifier().isValidSignatureNow(
                dataHash, 
                verifierSignature
        ), "NFT2: Verifier must be valid");
    }

    /**
     *
     * This function appears to be a safeMint function for an NFT contract.
     * When called, it mints a new token with the specified tokenId and uri and assigns
     * it to the specified to address. It also applies a system fee and uses a verifier
     * to ensure that the verifierSignature is valid.
     *
     * @dev Mints a new NFT
     * @param to The address to mint the NFT to
     * @param tokenId The ID of the NFT
     * @param uri The URI of the NFT
     * @param nonce The nonce of the NFT
     * @param verifierSignature The signature of the verifier
     */
    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri,
        uint256 nonce,
        bytes memory verifierSignature
    ) public payable override(INFT2, INFT2Mintable) {
        _validateVerifierForTokenURI(tokenId, uri, nonce, verifierSignature);

        applySystemFee(keccak256("MINT_NFT"));
        _safeMint(to, tokenId, uri, to, 0);
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        string memory uri,
        uint96 feeNumerator
    ) internal {
        _safeMint(to, tokenId, uri, to, feeNumerator);
    }

    function safeMintAndData(
        address to,
        uint256 tokenId,
        string memory uri,
        uint96 feeNumerator,
        uint256 nonce,
        bytes memory verifierSignature
    ) public payable override {
        _validateVerifierForTokenURI(tokenId, uri, nonce, verifierSignature);

        applySystemFee(keccak256("MINT_NFT"));
        _safeMint(to, tokenId, uri, feeNumerator);
    }

    function safeMintBatch(
        address[] calldata tos,
        uint256[] calldata tokenIds,
        string[] memory uris,
        uint96[] calldata feeNumerators,
        uint256[] calldata nonces,
        bytes[] memory verifierSignatures
    ) public payable override {
        require(
            tokenIds.length > 0,
            "NFT2: List tokenIds must be granter than zero"
        );
        require(
            tos.length == tokenIds.length &&
                tokenIds.length == uris.length &&
                uris.length == feeNumerators.length &&
                feeNumerators.length == nonces.length &&
                nonces.length == verifierSignatures.length,
            "NFT2: Lists must have the same length"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _validateVerifierForTokenURI(tokenIds[i], uris[i], nonces[i], verifierSignatures[i]);
        }

        applySystemFee(keccak256("MINT_NFT"), tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            address to = tos[i];
            uint256 tokenId = tokenIds[i];
            string memory uri = uris[i];
            uint96 feeNumerator = feeNumerators[i];

            _safeMint(to, tokenId, uri, feeNumerator);
        }
    }

    function setRoyalties(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public virtual override onlyOwnerAndCreator(tokenId) {
        _setRoyalties(tokenId, receiver, feeNumerator);
    }

    function feeController() public view override returns (address) {
        return _feeController;
    }

    function setFeeController(
        address feeController_
    ) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _feeController = feeController_;
    }

    function dataSourceRegistry() public view returns(address) {
        return _dataSourceRegistry;
    }

    function setDataSourceRegistry(address dataSourceRegistry_) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _dataSourceRegistry = dataSourceRegistry_;
    }

    function claimRoyalty(address[] calldata tokens) public payable override {
        applySystemFee(keccak256("CLAIM_ROYALTY"));
        super.claimRoyalty(tokens);
    }

    function setData(
        uint256 tokenId,
        bytes32 dataKey,
        bytes memory dataValue,
        uint256 nonce,
        address source,
        bytes memory sourceSignature,
        bytes memory verifierSignature
    ) public payable virtual override {
        // fee apply
        applySystemFee(keccak256("SET_METADATA"));
        super.setData(
            tokenId,
            dataKey,
            dataValue,
            nonce,
            source,
            sourceSignature,
            verifierSignature
        );
    }

    function setData(
        uint256 tokenId,
        bytes32[] memory dataKeys,
        bytes[] memory dataValues,
        uint256 nonce,
        address source,
        bytes calldata sourceSignature,
        bytes calldata verifierSignature
    ) public payable virtual override {
        // fee apply
        applySystemFee(keccak256("SET_METADATA"), dataKeys.length);
        super.setData(
            tokenId,
            dataKeys,
            dataValues,
            nonce,
            source,
            sourceSignature,
            verifierSignature
        );
    }

    function _afterVerifyWriter(
        uint256,
        bytes32 dataKey,
        bytes memory,
        address
    ) internal view virtual override {
        // check in whitelist
        if (dataSourceRegistry() != address(0) && dataSourceRegistry()
            .supportsInterface(type(IDataSourceRegistry).interfaceId)) {
            address namespace = dataKey.namespace();
            IDataSourceRegistry(dataSourceRegistry()).isDataSource(namespace);
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(AccessControlUpgradeable, IERC165Upgradeable, NFT2Core)
        returns (bool)
    {
        return
            NFT2Core.supportsInterface(interfaceId) ||
            interfaceId == type(IFeeSupported).interfaceId ||
            interfaceId == type(INFT2).interfaceId ||
            interfaceId == type(INFT2Mintable).interfaceId ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }
}