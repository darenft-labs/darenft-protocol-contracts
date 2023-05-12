// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {ERC165CheckerUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import {IRoyalty} from "./IRoyalty.sol";
import {IDerivativeNFT2} from "../NFT2/IDerivativeNFT2.sol";
import {INFT2Core} from "../NFT2/INFT2Core.sol";

contract Royalty is IERC2981Upgradeable, IRoyalty, ERC165Upgradeable {
    using ERC165CheckerUpgradeable for address;

    bytes32 public constant SET_ROYALTY_ROLE = keccak256("SET_ROYALTY_ROLE");

    struct RoyaltyInfo {
        address creator;
        uint96 royaltyFraction;
    }

    mapping(uint256 => RoyaltyInfo) private mappedRoyalty;

    function getTokenCreator(uint256 tokenId) public view returns (address) {
        return mappedRoyalty[tokenId].creator;
    }

    function claimRoyalty(address[] calldata tokens) public payable virtual {
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 totalRoyalty = token != address(0)
                ? IERC20Upgradeable(token).balanceOf(address(this))
                : getBalance();
            address receiver = INFT2Core(address(this)).getContractCreator();

            if (totalRoyalty > 0) {
                if (
                    address(this).supportsInterface(
                        type(IDerivativeNFT2).interfaceId
                    )
                ) {
                    (
                        address parentToken,
                        uint256 parentTokenId
                    ) = IDerivativeNFT2(address(this)).getOriginalToken();

                    (
                        address parentRoyaltyReceiver,
                        uint256 parentRoyaltyAmount
                    ) = IRoyalty(parentToken).royaltyInfo(
                            parentTokenId,
                            totalRoyalty
                        );

                    _transferERC20(
                        token,
                        parentRoyaltyReceiver,
                        parentRoyaltyAmount
                    );

                    _transferERC20(
                        token,
                        receiver,
                        totalRoyalty - parentRoyaltyAmount
                    );
                } else {
                    _transferERC20(token, receiver, totalRoyalty);
                }
            }
        }
    }

    function _transferERC20(
        address token,
        address receiver,
        uint256 amount
    ) internal {
        if (token == address(0)) {
            require(
                getBalance() >= amount,
                "Royalty: Not enough native token in pool"
            );

            (bool success, ) = payable(receiver).call{value: amount}("");
            require(success, "Transfer failed");
        } else {
            uint8 decimals = IERC20MetadataUpgradeable(token).decimals();
            uint256 difference = 18 - decimals;

            uint256 total = amount / 10 ** difference;

            IERC20Upgradeable(token).transfer(receiver, total);
        }

        emit RoyaltyClaimed(token, receiver, amount);
    }

    function _setRoyalties(
        uint256 tokenId,
        address creator,
        uint96 feeNumerator
    ) internal virtual {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(creator != address(0), "ERC2981: Invalid parameters");

        mappedRoyalty[tokenId] = RoyaltyInfo(creator, feeNumerator);

        emit RoyaltyChanged(tokenId, creator, feeNumerator);
    }

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    )
        public
        view
        override(IERC2981Upgradeable, IRoyalty)
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalty = mappedRoyalty[_tokenId];

        receiver = royalty.creator;

        royaltyAmount =
            (_salePrice * royalty.royaltyFraction) /
            _feeDenominator();
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(IERC165Upgradeable, ERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            interfaceId == type(IRoyalty).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    receive() external payable {}

    fallback() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function feeRoyaltyDenominator() external pure override returns (uint96) {
        return _feeDenominator();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;

}
