// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

// interfaces
import "./IERC725Z2.sol";

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

// libraries
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

// modules
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./ERC725Z.sol";

import "./ERC725ZKeyLib.sol";

contract ERC725Z2 is ERC725Z, IERC725Z2 {
    using ERC725ZKeyLib for bytes32;
    using SignatureCheckerUpgradeable for address;
    using ECDSAUpgradeable for bytes32;

    /** EIP 712 Impl */
    bytes32 private constant _HASHED_NAME = keccak256(bytes("ERC725Z2"));
    bytes32 private constant _HASHED_VERSION = keccak256(bytes("0.0.1"));

    bytes32 private constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 constant SET_DATA_HASH =
        keccak256(
            "SetData(uint256 nonce,uint256 tokenId,bytes32 dataKey,bytes dataValue)"
        );

    bytes32 constant SET_MULTIPLE_DATA_HASH =
        keccak256(
            "SetData(uint256 nonce,uint256 tokenId,bytes32[] dataKeys,bytes[] dataValues)"
        );

    bytes32 private _domainSeparator;

    /**
     * @dev nonces of signers
     * address => channelId => nonce
     */
    mapping(address => mapping(uint256 => uint256)) internal _nonceStores;

    address internal _verifier;

    function __ERC725Z2_init(
        address admin,
        address verifier_
    ) internal onlyInitializing {
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __ERC725Z_init_unchained(admin);
        __ERC725Z2_init_unchained(verifier_);
    }

    function __ERC725Z2_init_unchained(
        address verifier_
    ) internal onlyInitializing {
        _domainSeparator = _buildDomainSeparator(
            _TYPE_HASH,
            _HASHED_NAME,
            _HASHED_VERSION
        );
        _verifier = verifier_;
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 name,
        bytes32 version
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    name,
                    version,
                    block.chainid,
                    address(this)
                )
            );
    }

    function buildDomainSeparator(
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _TYPE_HASH,
                    _HASHED_NAME,
                    _HASHED_VERSION,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(
        bytes32 structHash
    ) internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", _domainSeparator, structHash)
            );
    }

    function verifier() public view returns (address) {
        return _verifier;
    }

    function getNonce(
        address signer,
        uint128 channelId
    ) public view returns (uint256) {
        return _nonceStores[signer][channelId];
    }

    function generateDataHash(
        uint256 nonce,
        uint256 tokenId,
        bytes32 dataKey,
        bytes memory dataValue
    ) public view returns(bytes32) {
        return _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        SET_DATA_HASH,
                        nonce,
                        tokenId,
                        dataKey,
                        keccak256(dataValue)
                    )
                )
            );
    }

    function generateDataHash(
        uint256 nonce,
        uint256 tokenId,
        bytes32[] memory dataKeys,
        bytes[] memory dataValues
    ) public view returns(bytes32) {

        bytes memory dataValueHash;
        for (uint i = 0; i < dataValues.length; i = _uncheckedIncrement(i)) {
            dataValueHash = abi.encodePacked(dataValueHash, keccak256(dataValues[i]));
        }

        return _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        SET_MULTIPLE_DATA_HASH,
                        nonce,
                        tokenId,
                        keccak256(abi.encodePacked(dataKeys)),
                        keccak256(dataValueHash)
                    )
                )
            );
    }

    function _verifyWriter(
        uint256 nonce,
        uint256 tokenId,
        bytes32 dataKey,
        bytes memory dataValue,
        address source,

        bytes memory sourceSignature,
        bytes memory verifierSignature
    ) internal {
        require(getNonce(source, uint128(tokenId)) == nonce, "ERC725Z2: nonce mismatch");

        bytes32 dataHash = generateDataHash(nonce, tokenId, dataKey, dataValue);

        require(
            source.isValidSignatureNow(dataHash, sourceSignature),
            "ERC725Z2: invalid source signature"
        );

        require(
            verifier() != address(0) &&
                verifier().isValidSignatureNow(
                    dataHash,
                    verifierSignature
                ),
            "ERC725Z2: invalid verifier signature"
        );
        
        // check namespace in registry
        address namespace = dataKey.namespace();



        // default namespace
        if (namespace == address(0)) {
            require(
                source == verifier(),
                "ERC725Z2: can not write to default namespace"
            );
        } else {
            require(
                namespace == source,
                "ERC7252Z2: can not write to this namespace"
            );
        }

        _nonceStores[source][uint128(tokenId)]++;

        _afterVerifyWriter(tokenId, dataKey, dataValue, source);
    }

    function _verifyWriter(
        uint256 nonce,
        uint256 tokenId,
        bytes32[] memory dataKeys,
        bytes[] memory dataValues,
        address source,

        bytes memory sourceSignature,
        bytes memory verifierSignature
    ) internal {
        // nonce
        require(getNonce(source, uint128(tokenId)) == nonce, "ERC725Z2: nonce mismatch");
        bytes32 dataHash = generateDataHash(nonce, tokenId, dataKeys, dataValues);

        require(
            source.isValidSignatureNow(dataHash, sourceSignature),
            "ERC725Z2: invalid source signature"
        );

        require(
            verifier() != address(0) &&
                verifier().isValidSignatureNow(
                    dataHash,
                    verifierSignature
                ),
            "ERC725Z2: invalid verifier signature"
        );
        
        // check namespace in registry
        for (uint256 i = 0; i < dataKeys.length; i = _uncheckedIncrement(i)) {
            address namespace = dataKeys[i].namespace();
            if (namespace == address(0)) {
                require(
                    source == verifier(),
                    "ERC725Z2: can not write to default namespace"
                );
            } else {
                require(
                    namespace == source,
                    "ERC7252Z2: can not write to this namespace"
                );
            }
        }

        _nonceStores[source][uint128(tokenId)]++;

        for (uint256 i = 0; i < dataKeys.length; i = _uncheckedIncrement(i)) {
            _afterVerifyWriter(tokenId, dataKeys[i], dataValues[i], source);            
        }
    }

    function _afterVerifyWriter(
        uint256 tokenId,
        bytes32 dataKey,
        bytes memory dataValue,
        address source
    ) internal virtual view {

    }

    /**
     * @inheritdoc IERC725Z
     */
    function setData(
        uint256 tokenId,
        bytes32 dataKey,
        bytes memory dataValue
    ) public virtual override(ERC725Z, IERC725Z) {
        require(
            dataKey.namespace() == _msgSender(),
            "ERC7252Z2: can not write to this namespace"
        );
        _setData(tokenId, dataKey, dataValue);
    }

    /**
     * @inheritdoc IERC725Z
     */
    function setData(
        uint256 tokenId,
        bytes32[] memory dataKeys,
        bytes[] memory dataValues
    )
        public
        virtual
        override(ERC725Z, IERC725Z)
        onlyRole(METADATA_ROLE)
    {
        require(
            dataKeys.length == dataValues.length,
            "Keys length not equal to values length"
        );
        for (uint256 i = 0; i < dataKeys.length; i = _uncheckedIncrement(i)) {
            require(
                dataKeys[i].namespace() == _msgSender(),
                "ERC7252Z2: can not write to this namespace"
            );
            _setData(tokenId, dataKeys[i], dataValues[i]);
        }
    }

    function setData(
        uint256 tokenId,
        bytes32 dataKey,
        bytes memory dataValue,
        uint256 nonce,
        address source,
        bytes memory sourceSignature,
        bytes memory verifierSignature
    ) public virtual payable override {
        _verifyWriter(nonce, tokenId, dataKey, 
            dataValue, 
            source, 
            sourceSignature, 
            verifierSignature
        );
        _setData(tokenId, dataKey, dataValue);
    }

    function setData(
        uint256 tokenId,
        bytes32[] memory dataKeys,
        bytes[] memory dataValues,
        uint256 nonce,
        address source,
        bytes calldata sourceSignature,
        bytes calldata verifierSignature
    ) public virtual payable override {
        require(
            dataKeys.length == dataValues.length,
            "Keys length not equal to values length"
        );

        _verifyWriter(
            nonce, 
            tokenId,
            dataKeys,
            dataValues,
            source,
            sourceSignature,
            verifierSignature
        );

        for (uint256 i = 0; i < dataKeys.length; i = _uncheckedIncrement(i)) {
            _setData(tokenId, dataKeys[i], dataValues[i]);            
        }
    }

    /**
     * @inheritdoc ERC165Upgradeable
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC725Z) returns (bool) {
        return
            interfaceId == type(IERC725Z2).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}
