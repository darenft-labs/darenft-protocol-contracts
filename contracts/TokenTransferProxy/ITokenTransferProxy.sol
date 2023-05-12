// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ITokenTransferProxy {
    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    function nft721TransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) external returns (bool);

    function nft1155TransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external returns (bool);
}
