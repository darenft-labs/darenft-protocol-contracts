// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// modules
import {ClonesUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import {ERC165CheckerUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {OwnableUnset} from "@erc725/smart-contracts/contracts/custom/OwnableUnset.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC1271Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "../middlewares/Forwarder.sol";
import "../utils/fee/FeeSupported.sol";

// interfaces
import "../utils/fee/IFeeSupported.sol";
import "../NFT2/INFT2.sol";
import "../NFT2/IDerivativeNFT2.sol";
import "../NFT2/INFT2Core.sol";
import "../Vault/INFT2Vault.sol";
import "../utils/universal-receiver/IUniversaleReceiver.sol";

import "./INFTFactory.sol";

// libraries
import "../NFT2/constants.sol";
// extensions

contract NFTFactory is
    MiddlewareForwarder,
    ERC165Upgradeable,
    AccessControlUpgradeable,
    IUniversaleReceiver,
    INFTFactory,
    FeeSupported,
    IERC1271Upgradeable
{
    using ERC165CheckerUpgradeable for address;
    using ECDSAUpgradeable for bytes32;

    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    struct OriginalToken {
        address token;
        uint256 tokenId;
    }

    mapping(address => uint256) internal nft2Nonces;
    mapping(address => mapping(uint256 => address)) internal nft2Mappings;
    mapping(address => OriginalToken) internal nftOriginalMappings;
    mapping(address => mapping(uint256 => address))
        internal nftDerivativeMappings;

    INFT2Vault public nft2Vault;
    address public nft2Implementation;
    address public nft2DerivativeImplementation;
    address internal _feeController;
    address public nft2AutoIdImplementation;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner) public initializer {
        __ERC165_init_unchained();
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __MiddlewareForwarderContext_init_unchained();

        address defaultAdmin = _msgSender();
        if (owner != address(0)) {
            defaultAdmin = owner;
        }

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(FACTORY_ROLE, defaultAdmin);
        _grantRole(VERIFIER_ROLE, defaultAdmin);
    }

    function _msgSender()
        internal
        view
        override(ContextUpgradeable, MiddlewareForwarder)
        returns (address)
    {
        return MiddlewareForwarder._msgSender();
    }

    function setNFT2Vault(address nft2Vault_) public onlyRole(FACTORY_ROLE) {
        nft2Vault = INFT2Vault(nft2Vault_);
    }

    function setNFT2Implementation(address nft2Implementation_)
        public
        onlyRole(FACTORY_ROLE)
    {
        nft2Implementation = nft2Implementation_;
    }

    function setNFT2AutoIdImplementation(address nft2AutoIdImplementation_)
        public
        onlyRole(FACTORY_ROLE)
    {
        nft2AutoIdImplementation = nft2AutoIdImplementation_;
    }

    function setNFT2DerivativeImplementation(
        address nft2DerivativeImplementation_
    ) public onlyRole(FACTORY_ROLE) {
        nft2DerivativeImplementation = nft2DerivativeImplementation_;
    }

    function nftOf(address provider, uint256 nonce)
        public
        view
        returns (address)
    {
        return nft2Mappings[provider][nonce];
    }

    function getNFT2(
        address logic,
        address provider,
        uint256 nonce
    ) public view returns (address, bytes32) {
        bytes32 salt_ = keccak256(abi.encode(provider, nonce));

        address newNFT2 = ClonesUpgradeable.predictDeterministicAddress(
            logic,
            salt_,
            address(this)
        );

        return (newNFT2, salt_);
    }

    function _deployNFT2(
        address nft2Logic_,
        address provider_,
        bytes memory initialCode_,
        string memory tokenName,
        string memory symbol
    ) internal returns (address) {
        require(
            nft2Logic_.supportsInterface(type(INFT2Core).interfaceId),
            "NFTFactory: logic must be INFT2Core compatible"
        );

        require(
            nft2Logic_.supportsInterface(type(INFT2).interfaceId) ||
                nft2Logic_.supportsInterface(type(INFT2AutoID).interfaceId),
            "NFTFactory: logic must be INFT2 or INFT2AutoID compatible"
        );

        // non-reentrancy
        (address newNFT2, bytes32 salt_) = getNFT2(
            nft2Logic_,
            provider_,
            nft2Nonces[provider_]
        );

        ClonesUpgradeable.cloneDeterministic(nft2Logic_, salt_);

        AddressUpgradeable.functionCall(
            newNFT2,
            initialCode_
            // msg.value - sfee
        );

        if (newNFT2.supportsInterface(type(IFeeSupported).interfaceId)) {
            IFeeSupported(newNFT2).setFeeController(feeController());
        }

        nft2Mappings[provider_][nft2Nonces[provider_]] = newNFT2;
        nft2Nonces[provider_] += 1;

        emit NFT2Created(newNFT2, provider_, nft2Logic_, tokenName, symbol);

        return newNFT2;
    }

    function deployNFT2(
        string memory tokenName,
        string memory symbol,
        address owner
    ) public payable {
        bytes memory _initialData = abi.encodeWithSignature(
            "initialize(string,string,address,address,address)",
            tokenName,
            symbol,
            owner,
            owner,
            address(this) // _msgSender()
        );

        applySystemFee(keccak256("DEPLOY_NFT"));

        address provider_ = _msgSender();

        _deployNFT2(
            nft2Implementation,
            provider_,
            _initialData,
            tokenName,
            symbol
        );
    }

    function deployNFT2AutoId(
        string memory tokenName,
        string memory symbol,
        address owner
    ) public payable {
        bytes memory _initialData = abi.encodeWithSignature(
            "initialize(string,string,address,address,address)",
            tokenName,
            symbol,
            owner,
            owner,
            address(this)
            // _msgSender()
        );
        applySystemFee(keccak256("DEPLOY_NFT"));

        address provider_ = _msgSender();

        _deployNFT2(
            nft2AutoIdImplementation,
            provider_,
            _initialData,
            tokenName,
            symbol
        );
    }

    function nftDerivativeOf(address tokenNFT2, uint256 tokenIdNFT2)
        public
        view
        returns (address)
    {
        return nftDerivativeMappings[tokenNFT2][tokenIdNFT2];
    }

    function nftOriginalOf(address tokenNFT2Derivative)
        public
        view
        returns (OriginalToken memory)
    {
        return nftOriginalMappings[tokenNFT2Derivative];
    }

    function getNFT2Derivative(
        address logic,
        address tokenNFT2,
        uint256 tokenIdNFT2
    ) public view returns (address, bytes32) {
        bytes32 salt_ = keccak256(abi.encode(tokenNFT2, tokenIdNFT2));

        address newNFT2Derivative = ClonesUpgradeable
            .predictDeterministicAddress(logic, salt_, address(this));

        return (newNFT2Derivative, salt_);
    }

    function _deployNFT2Derivative(
        address nft2DerivativeLogic_,
        address tokenNFT2_,
        uint256 tokenIdNFT2_,
        bytes memory initialCode_,
        string memory tokenName,
        string memory symbol
    ) internal returns (address) {
        require(
            tokenNFT2_.supportsInterface(type(IERC721Upgradeable).interfaceId),
            "NFTFactory: token must be ERC721 compatible"
        );

        require(
            nft2DerivativeLogic_.supportsInterface(type(INFT2Core).interfaceId),
            "NFTFactory: logic must be INFT2Core compatible"
        );

        require(
            nft2DerivativeLogic_.supportsInterface(
                type(IDerivativeNFT2).interfaceId
            ),
            "NFTFactory: logic must be INFT2 compatible"
        );

        // non-reentrancy
        (address newNFT2Derivative, bytes32 salt_) = getNFT2Derivative(
            nft2DerivativeLogic_,
            tokenNFT2_,
            tokenIdNFT2_
        );
        nftDerivativeMappings[tokenNFT2_][tokenIdNFT2_] = newNFT2Derivative;
        nftOriginalMappings[newNFT2Derivative] = OriginalToken({
            token: tokenNFT2_,
            tokenId: tokenIdNFT2_
        });
        setTrustedForwarder(newNFT2Derivative, true);

        ClonesUpgradeable.cloneDeterministic(nft2DerivativeLogic_, salt_);

        AddressUpgradeable.functionCall(newNFT2Derivative, initialCode_);

        if (
            newNFT2Derivative.supportsInterface(type(IFeeSupported).interfaceId)
        ) {
            IFeeSupported(newNFT2Derivative).setFeeController(feeController());
        }

        emit NFT2DerivativeCreated(
            newNFT2Derivative,
            tokenNFT2_,
            tokenIdNFT2_,
            nft2DerivativeLogic_,
            tokenName,
            symbol
        );

        return newNFT2Derivative;
    }

    function deployNFT2Derivative(
        address tokenNFT2_,
        uint256 tokenIdNFT2_,
        address owner
    ) public payable {
        address created = nftDerivativeOf(tokenNFT2_, tokenIdNFT2_);

        require(
            created == address(0),
            "NFTFactory: NFT already has its derivative"
        );

        applySystemFee(keccak256("DEPLOY_DERIVATIVE_NFT"));

        string memory tokenName = string(
            abi.encodePacked(
                "Derivative",
                "-",
                IERC721Metadata(tokenNFT2_).name()
            )
        );
        string memory symbol = string(
            abi.encodePacked("D", "-", IERC721Metadata(tokenNFT2_).symbol())
        );

        bytes memory _initialData = abi.encodeWithSignature(
            "initialize(string,string,address,address,address,address,uint256)",
            tokenName,
            symbol,
            owner,
            address(this),
            address(this),
            tokenNFT2_,
            tokenIdNFT2_
        );

        _deployNFT2Derivative(
            nft2DerivativeImplementation,
            tokenNFT2_,
            tokenIdNFT2_,
            _initialData,
            tokenName,
            symbol
        );
    }

    /**
     * Reserved code for future
     */
    function mintNFT2FromOriginalNFT(
        address from,
        address token,
        uint256 tokenId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // address nft2Token = nftOf(token);
        // uint256 nft2TokenId = tokenId;
        // IOriginalNFTVault vault = IOriginalNFTVault(originalNFTVault);
        // require(
        //     !vault.isLockedNFT(token, tokenId),
        //     "NFTFactory: Token ID already locked"
        // );
        // vault.lockOriginalNFT(from, token, tokenId, nft2Token, nft2TokenId);
        // INFT2(nft2Token).safeMint(from, nft2TokenId, "");
        // emit NFT2Minted(token, tokenId, nft2Token, nft2TokenId);
    }

    function isLockedNFT2(address token, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return nft2Vault.isLockedNFT2(token, tokenId);
    }

    function lockNFT2(address nft2Token, uint256 nft2TokenId) public {
        address from = _msgSender();

        nft2Vault.lockNFT2(from, nft2Token, nft2TokenId);
    }

    function releaseNFT2(
        address nft2Token,
        uint256 nft2TokenId,
        address to
    ) public {
        address from = _msgSender();
        nft2Vault.releaseNFT2(nft2Token, nft2TokenId, from, to);
    }

    function mintDerivativeNFT2(
        address to,
        address provider,
        address nft2Token,
        uint256 nft2TokenId,
        string memory uri,

        uint256 nonce,
        bytes memory verifierSignature
    ) public payable {
        address from = _msgSender();
        require(
            nft2Vault.isLockedNFT2(nft2Token, nft2TokenId),
            "NFTFactory: NFT2 not locked yet"
        );

        require(
            nft2Vault.getOwnerOfLockedNFT2(nft2Token, nft2TokenId) == from,
            "NFTFactory: Account is not owner of nft2"
        );

        address derivativeNft2Token = nftDerivativeOf(nft2Token, nft2TokenId);

        uint256 derivativeNft2TokenId = IDerivativeNFT2(derivativeNft2Token)
            .safeMint{value: msg.value}(to, uri, provider, nonce, verifierSignature);

        nft2Vault.setDerivativeNFT2ForNFT2(
            nft2Token,
            nft2TokenId,
            provider,
            derivativeNft2Token,
            derivativeNft2TokenId
        );

        emit NFT2DerivativeMinted(
            to,
            provider,
            nft2Token,
            nft2TokenId,
            derivativeNft2Token,
            derivativeNft2TokenId
        );
    }

    function _requireTokenLock(address nft2Token, uint256 nft2TokenId) internal view virtual {
        address from = _msgSender();
        require(
            nft2Vault.isLockedNFT2(nft2Token, nft2TokenId),
            "NFTFactory: NFT2 not locked yet"
        );

        require(
            nft2Vault.getOwnerOfLockedNFT2(nft2Token, nft2TokenId) == from,
            "NFTFactory: Account is not owner of nft2"
        );
    }

    function mintDerivativeNFT2AndSetInfo(
        address to,
        address provider,
        address nft2Token,
        uint256 nft2TokenId,
        string memory uri,
        uint256 openTime,
        uint256 closingTime,
        uint96 feeNumerator,

        uint256 nonce,
        bytes memory verifierSignature
    ) public payable {
        _requireTokenLock(nft2Token, nft2TokenId);

        address derivativeNft2Token = nftDerivativeOf(nft2Token, nft2TokenId);

        uint256 derivativeNft2TokenId = IDerivativeNFT2(derivativeNft2Token)
            .safeMintAndSetInfo{value: msg.value}(
            to,
            uri,
            provider,
            openTime,
            closingTime,
            feeNumerator,

            nonce,
            verifierSignature
        );

        nft2Vault.setDerivativeNFT2ForNFT2(
            nft2Token,
            nft2TokenId,
            provider,
            derivativeNft2Token,
            derivativeNft2TokenId
        );

        emit NFT2DerivativeMinted(
            to,
            provider,
            nft2Token,
            nft2TokenId,
            derivativeNft2Token,
            derivativeNft2TokenId
        );
    }

    function _removeDerivativeNFT2(
        address derivativeNft2Token,
        uint256 derivativeNft2TokenId
    ) internal {
        require(
            !INFT2Core(derivativeNft2Token).exists(derivativeNft2TokenId),
            "NFTFactory: NFT2 not burned yet"
        );

        (
            address provider,
            address nft2Token,
            uint256 nft2TokenId
        ) = IDerivativeNFT2(derivativeNft2Token).getTokenDetail(
                derivativeNft2TokenId
            );

        nft2Vault.removeDerivativeNFT2(
            nft2Token,
            nft2TokenId,
            provider,
            derivativeNft2Token
        );
    }

    function universalReceiver(bytes32 typeId, bytes calldata receivedData)
        public
    {
        if (typeId == DERIVATIVE_NFT_BURN_EVENT) {
            (address tokenAddress, uint256 tokenId) = abi.decode(
                receivedData,
                (address, uint256)
            );
            _removeDerivativeNFT2(tokenAddress, tokenId);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IFeeSupported).interfaceId ||
            interfaceId == type(IUniversaleReceiver).interfaceId ||
            interfaceId == type(IERC1271Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function feeController() public view override returns (address) {
        return _feeController;
    }

    function setFeeController(address feeController_)
        public
        virtual
        onlyRole(FACTORY_ROLE)
    {
        _feeController = feeController_;
    }

    function isValidSignature(bytes32 _hash, bytes memory signature) external view returns (bytes4 magicValue) {
        // Validate signatures
        if (hasRole(VERIFIER_ROLE, _hash.recover(signature))) {
            return 0x1626ba7e;
        }

        return 0xffffffff;
    }
}
