// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import {IDerivativeNFT2} from "./IDerivativeNFT2.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";

import {TimeHelper} from "../utils/timer/TimeHelper.sol";
import {NFT2Core} from "./NFT2Core.sol";

import "../utils/fee/FeeSupported.sol";
import "../utils/fee/IFeeSupported.sol";

import "../Royalty/IRoyalty.sol";
import "../ERC725Z/ERC725ZKeyLib.sol";
import "./constants.sol";

import "../ERC725Z/ERC725Z2.sol";

contract DerivativeNFT2 is
    Initializable,
    AccessControlUpgradeable,
    NFT2Core,
    TimeHelper,
    IDerivativeNFT2,
    FeeSupported
{
    using AddressUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using ERC725ZKeyLib for bytes32;
    using SignatureCheckerUpgradeable for address;
    using ERC165CheckerUpgradeable for address;

    struct ParentToken {
        address token;
        uint256 tokenId;
    }

    CountersUpgradeable.Counter public tokenIdTracker;

    ParentToken parent;

    mapping(address => uint256) private currentTokenMappings;
    mapping(uint256 => address) private providerTokenMappings;

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
        address metadataAdmin,
        address parentToken,
        uint256 parentTokenId
    ) public initializer {
        __AccessControl_init_unchained();

        address defaultAdmin = _msgSender();
        if (owner != address(0)) {
            defaultAdmin = owner;
        }

        __DerivativeNFT2_init(
            tokenName,
            symbol,
            owner,
            minter,
            metadataAdmin,
            parentToken,
            parentTokenId
        );
    }

    function __DerivativeNFT2_init(
        string memory tokenName,
        string memory symbol,
        address owner,
        address minter,
        address metadataAdmin,
        address parentToken,
        uint256 parentTokenId
    ) internal onlyInitializing {
        __AccessControl_init_unchained();


        __ERC725Z_init_unchained(metadataAdmin);
        __ERC721_init_unchained(tokenName, symbol);

        address defaultAdmin = _msgSender();
        if (owner != address(0)) {
            defaultAdmin = owner;
        }


        __NFT2Core_init_unchained(
            minter,
            defaultAdmin
        );

        __DerivativeNFT2_init_unchained(
            parentToken,
            parentTokenId,
            defaultAdmin
        );
    }

    function __DerivativeNFT2_init_unchained(
        address parentToken,
        uint256 parentTokenId,
        address defaultAdmin
    ) internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        
        tokenIdTracker.increment();
        parent = ParentToken({token: parentToken, tokenId: parentTokenId});
    }

    function getOriginalToken() public view returns (address, uint256) {
        ParentToken memory parentToken = parent;

        return (parentToken.token, parentToken.tokenId);
    }

    function getTokenDetail(uint256 tokenId)
        public
        view
        returns (
            address,
            address,
            uint256
        )
    {
        ParentToken memory parentToken = parent;

        return (
            providerTokenMappings[tokenId],
            parentToken.token,
            parentToken.tokenId
        );
    }

    function getCurrentToken(address provider) public view returns (uint256) {
        return currentTokenMappings[provider];
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
            bytes(uri)
        );

        require(verifier() != address(0), "NFT2: Verifier must be set");
        require(verifier().isValidSignatureNow(dataHash, verifierSignature), "NFT2: Verifier must be set");
    }

    function safeMint(
        address to,
        string memory uri,
        address provider,

        uint256 nonce,
        bytes memory verifierSignature
    ) public payable override returns (uint256) {
        require(
            getCurrentToken(provider) == 0,
            "DerivativeNFT2: Parent token already existed"
        );

        uint256 currentTokenId = tokenIdTracker.current();

        currentTokenMappings[provider] = currentTokenId;
        providerTokenMappings[currentTokenId] = provider;

        _validateVerifierForTokenURI(
            0,
            uri,
            nonce,
            verifierSignature
        );

        applySystemFee(keccak256("MINT_DERIVATIVE_NFT"));
        _safeMint(to, currentTokenId, uri, getContractCreator(), 0);


        tokenIdTracker.increment();

        
        return currentTokenId;
    }

    function safeMintAndSetInfo(
        address to,
        string memory uri,
        address provider,
        uint256 openTime,
        uint256 closingTime,
        uint96 feeNumerator,

        uint256 nonce,
        bytes memory verifierSignature
    ) public payable override returns (uint256) {
        uint256 tokenId = safeMint(to, uri, provider, nonce, verifierSignature);

        _setRoyalties(tokenId, getContractCreator(), feeNumerator);
        _setTime(tokenId, openTime, closingTime);

        return tokenId;
    }

    function setRoyalties(uint256 tokenId, uint96 feeNumerator)
        public
        onlyOwnerAndCreator(tokenId)
    {
        _setRoyalties(tokenId, getContractCreator(), feeNumerator);
    }

    function setTime(
        uint256 tokenId,
        uint256 openTime,
        uint256 closingTime
    ) public onlyOwnerAndCreator(tokenId) {
        address executor = _msgSender();
        address creator = getTokenCreator(tokenId);

        require(creator == executor, "DerivativeNFT2: Account is not creator");

        _setTime(tokenId, openTime, closingTime);
    }

    function burn(uint256 tokenId) public payable override {
        require(exists(tokenId), "DerivativeNFT2: Token not found");

        address executor = _msgSender();

        /**
         * Owner can burn anytime, but creator only has permission to burn after deadline
         */
        if (ownerOf(tokenId) == executor) {
            _burn(tokenId);
        } else {
            if (!isOpen(tokenId)) {
                address creator = getTokenCreator(tokenId);

                require(
                    creator == executor,
                    "DerivativeNFT2: Account is not creator"
                );

                // Creator can burn the token
                _burn(tokenId);
            } else {
                revert("DerivativeNFT2: Account is not owner");
            }
        }

        (address provider, , ) = getTokenDetail(tokenId);
        delete currentTokenMappings[provider];
        delete providerTokenMappings[tokenId];
    }

    function _beforeMintToken(address, address, uint256 tokenId) internal {
        _setTime(tokenId, 0, 0); // default as inactive
    }

    function _beforeBurnToken(address from, address to, uint256 tokenId) internal {
        // do nothing ...
    }

    function _beforeTransferToCreator(address from, address to, uint256 tokenId) internal {
        // do nothing ...
    }

    function _beforeTransferToOther(address, address, uint256 tokenId) internal {
        // reset remaining
        uint256 openingTime = getOpeningTime(tokenId);
        uint256 closingTime = getClosingTime(tokenId);

        // inactive -> auto active transfer
        if (openingTime == 0) {
            _setTime(tokenId, block.timestamp, block.timestamp + closingTime);
        } else {
            // do nothing ...
            // must be active on tranfer to other account
            require(isOpen(tokenId), "DerivativeNFT2: Token is in-active");
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override whenNotPaused {
        // mint

        if (from == address(0)) {
            _beforeMintToken(from, to, tokenId);
        } else if (to == address(0)) {
            _beforeBurnToken(from, to, tokenId);
        } else {
            address currentOwnerOfParentNFT = IRoyalty(parent.token)
                .getTokenCreator(parent.tokenId);

            // receiver as owner
            if (to == currentOwnerOfParentNFT) {
                _beforeTransferToCreator(from, to, tokenId);
            } else {
                _beforeTransferToOther(from, to, tokenId);
            }
        }

        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable, NFT2Core, TimeHelper)
        returns (bool)
    {
        return
            interfaceId == type(IFeeSupported).interfaceId ||
            interfaceId == type(IDerivativeNFT2).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function feeController() public view override returns (address) {
        return _feeController;
    }

    function setFeeController(address feeController_)
        public
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _feeController = feeController_;
    }

    function setData(
        uint256 tokenId,
        bytes32[] memory dataKeys,
        bytes[] memory dataValues
    ) public virtual override {
        // fee apply
        applySystemFee(keccak256("SET_METADATA"));
        super.setData(tokenId, dataKeys, dataValues);
    }

    function setData(
        uint256 tokenId,
        bytes32 dataKey,
        bytes memory dataValue
    ) public virtual override {
        // fee apply
        applySystemFee(keccak256("SET_METADATA"));
        super.setData(tokenId, dataKey, dataValue);
    }


    function _setData(
        uint256 tokenId,
        bytes32 dataKey,
        bytes memory dataValue
    ) internal virtual override {
        // forward to root parent
        if (providerTokenMappings[tokenId] == dataKey.namespace()) {
            IERC725Z2(parent.token).setData(tokenId, dataKey, dataValue);
        } else {
            super._setData(tokenId, dataKey, dataValue);
        }
    }

    function claimRoyalty(address[] calldata tokens) public payable override {
        applySystemFee(keccak256("CLAIM_ROYALTY"));
        super.claimRoyalty(tokens);
    }
}
