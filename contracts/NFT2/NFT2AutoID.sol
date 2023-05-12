// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "../utils/fee/FeeSupported.sol";
import "./NFT2Core.sol";

import "../utils/fee/IFeeSupported.sol";
import "./INFT2.sol";

import "./INFT2AutoIDMintable.sol";

contract NFT2AutoID is
    Initializable,
    AccessControlUpgradeable,
    NFT2Core,
    INFT2AutoID,
    FeeSupported,
    INFT2AutoIDMintable
{
    using AddressUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SignatureCheckerUpgradeable for address;

    CountersUpgradeable.Counter public tokenIdTracker;

    address internal _feeController;

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

    function __NFT2Auto_init_unchained() internal onlyInitializing {}

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


    function _safeMint(
        address to,
        string memory uri,
        address royaltyReceiver,
        uint96 feeNumerator
    ) internal {
        _safeMint(
            to,
            tokenIdTracker.current(),
            uri,
            royaltyReceiver,
            feeNumerator
        );

        tokenIdTracker.increment();
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

        require(
            verifier() != address(0) &&
                verifier().isValidSignatureNow(dataHash, verifierSignature),
            "NFT2: Verifier must be set"
        );
    }

    function safeMint(
        address to,
        string memory uri,
        uint256 nonce,
        bytes memory verifierSignature
    ) public payable override(INFT2AutoID, INFT2AutoIDMintable) {
        safeMintAndData(to, uri, 0, nonce, verifierSignature);
    }

    function safeMintAndData(
        address to,
        string memory uri,
        uint96 feeNumerator,
        uint256 nonce,
        bytes memory verifierSignature
    ) public payable override {
        _validateVerifierForTokenURI(0, uri, nonce, verifierSignature);

        applySystemFee(keccak256("MINT_NFT"));
        _safeMint(to, uri, to, feeNumerator);
    }

    function safeMintBatch(
        address[] calldata tos,
        string[] memory uris,
        uint96[] calldata feeNumerators,
        uint256[] calldata nonces,
        bytes[] calldata verifierSignatures
    ) public payable override {
        require(tos.length > 0, "NFT2: List tokens must be granter than zero");
        require(
            tos.length == uris.length,
            "NFT2: Lists must have the same length"
        );

        // verify signature
        for (uint256 i = 0; i < tos.length; i++) {
            _validateVerifierForTokenURI(0, uris[i], nonces[i], verifierSignatures[i]);
        }

        applySystemFee(keccak256("MINT_NFT"), tos.length);

        for (uint256 i = 0; i < tos.length; i++) {
            address to = tos[i];
            string memory uri = uris[i];
            uint96 feeNumerator = feeNumerators[i];

            _safeMint(to, uri, to, feeNumerator);
        }
    }

    function setRoyalties(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyOwnerAndCreator(tokenId) {
        _setRoyalties(tokenId, receiver, feeNumerator);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControlUpgradeable, NFT2Core) returns (bool) {
        return
            interfaceId == type(IFeeSupported).interfaceId ||
            interfaceId == type(INFT2AutoID).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function feeController() public view override returns (address) {
        return _feeController;
    }

    function setFeeController(
        address feeController_
    ) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _feeController = feeController_;
    }

    function claimRoyalty(address[] calldata tokens) public payable override {
        applySystemFee(keccak256("CLAIM_ROYALTY"));
        super.claimRoyalty(tokens);
    }

    function setData(
        uint256 tokenId,
        bytes32[] memory dataKeys,
        bytes[] memory dataValues
    ) public virtual override {
        // // fee apply
        // applySystemFee(keccak256("SET_METADATA"));

        super.setData(tokenId, dataKeys, dataValues);
    }

    function setData(
        uint256 tokenId,
        bytes32 dataKey,
        bytes memory dataValue
    ) public virtual override {
        // // fee apply
        // applySystemFee(keccak256("SET_METADATA"));

        super.setData(tokenId, dataKey, dataValue);
    }
}
