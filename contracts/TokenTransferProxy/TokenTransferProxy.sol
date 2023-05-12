// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./ITokenTransferProxy.sol";

contract TokenTransferProxy is AccessControlUpgradeable, ITokenTransferProxy {
    using AddressUpgradeable for address;
    bytes32 public constant TRANSFERABLE_ROLE = keccak256("TRANSFERABLE");

    function initialize(address owner) public initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, owner);
    }

    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) public onlyRole(TRANSFERABLE_ROLE) returns (bool _success) {
        return IERC20(_token).transferFrom(_from, _to, _amount);
    }

    function nft721TransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) public onlyRole(TRANSFERABLE_ROLE) returns (bool _success) {
        IERC721 erc721token = IERC721(_token);
        erc721token.safeTransferFrom(_from, _to, _tokenId);
        return true;
    }

    function nft1155TransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) public onlyRole(TRANSFERABLE_ROLE) returns (bool _success) {
        IERC1155 token = IERC1155(_token);
        token.safeTransferFrom(_from, _to, _tokenId, _amount, "");
        return true;
    }
}
