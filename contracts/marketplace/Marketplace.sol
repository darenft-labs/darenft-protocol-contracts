// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// modules
import {ClonesUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {ERC725YCore} from "@erc725/smart-contracts/contracts/ERC725YCore.sol";
import {ERC165CheckerUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

// interfaces
import "../TokenTransferProxy/ITokenTransferProxy.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IMarketplaceVault.sol";
import {IDerivativeNFT2} from "../NFT2/IDerivativeNFT2.sol";
import {IRoyalty} from "../Royalty/IRoyalty.sol";
import {INFT2Core} from "../NFT2/INFT2Core.sol";
import {ITimeHelper} from "../utils/timer/ITimeHelper.sol";

// libraries

// extensions

contract Marketplace is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    using AddressUpgradeable for address;
    using ERC165CheckerUpgradeable for address;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bytes32 public constant MARKET_OWNER = keccak256("MARKET_OWNER");

    event Sell(
        uint256 tokenId,
        address tokenAddress,
        address currency,
        uint256 salePrice,
        address seller
    );

    event Withdraw(uint256 tokenId, address tokenAddress);

    event Buy(
        uint256 tokenId,
        address tokenAddress,
        address currency,
        uint256 salePrice,
        address seller,
        address buyer
    );

    event OpenForRent(
        uint256 tokenId,
        address tokenAddress,
        address currency,
        uint256 salePrice,
        address lender,
        uint256 start,
        uint256 end
    );

    event Rent(
        uint256 tokenId,
        address tokenAddress,
        address currency,
        uint256 salePrice,
        address lender,
        address borrower
    );

    struct ListingPurchasedItem {
        uint256 tokenId;
        address tokenAddress;
        address currency;
        uint256 salePrice;
        address seller;
        bool existed;
    }

    struct ListingRentingItem {
        uint256 tokenId;
        address tokenAddress;
        address currency;
        uint256 salePrice;
        address lender;
        bool existed;
    }

    struct SellRequest {
        uint256 tokenId;
        address tokenAddress;
        address currency;
        uint256 salePrice;
    }

    struct PaymentRequest {
        uint256 tokenId;
        address tokenAddress;
    }

    ITokenTransferProxy public tokenTransferProxy;
    IMarketplaceVault public marketplaceVault;

    mapping(address => mapping(uint256 => ListingPurchasedItem))
        public listingPurchasedItems;
    mapping(address => mapping(uint256 => ListingRentingItem))
        public listingRentingItems;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner,
        address vault_,
        address tokenTransferProxy_
    ) public initializer {
        __Pausable_init();
        __AccessControl_init_unchained();

        address defaultAdmin = _msgSender();
        if (owner != address(0)) {
            defaultAdmin = owner;
        }

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, defaultAdmin);

        marketplaceVault = IMarketplaceVault(vault_);
        tokenTransferProxy = ITokenTransferProxy(tokenTransferProxy_);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function sell(SellRequest calldata data) public {
        address seller = _msgSender();
        uint256 tokenId = data.tokenId;
        address tokenAddress = data.tokenAddress;

        marketplaceVault.deposit(seller, data.tokenAddress, data.tokenId);

        listingPurchasedItems[data.tokenAddress][
            tokenId
        ] = ListingPurchasedItem({
            tokenId: tokenId,
            tokenAddress: data.tokenAddress,
            currency: data.currency,
            salePrice: data.salePrice,
            seller: seller,
            existed: true
        });

        emit Sell(tokenId, tokenAddress, data.currency, data.salePrice, seller);
    }

    function withdraw(address tokenAddress, uint256 tokenId) public {
        address seller = _msgSender();

        require(
            IERC721(tokenAddress).ownerOf(tokenId) == address(this),
            "MarketPlace: nft is not in the vault"
        );

        require(
            marketplaceVault.ownerOf(tokenAddress, tokenId) == seller,
            "MarketPlace: sender is not owner of nft"
        );

        ListingPurchasedItem memory item = listingPurchasedItems[tokenAddress][
            tokenId
        ];

        require(item.existed, "MarketPlace: NFT not existed");

        marketplaceVault.withdraw(seller, tokenAddress, tokenId);

        delete listingPurchasedItems[tokenAddress][tokenId];

        emit Withdraw(tokenId, tokenAddress);
    }

    function buy(PaymentRequest calldata payment)
        public
        payable
        virtual
        whenNotPaused
    {
        address buyer = _msgSender();
        uint256 tokenId = payment.tokenId;
        address tokenAddress = payment.tokenAddress;

        ListingPurchasedItem memory item = listingPurchasedItems[tokenAddress][
            tokenId
        ];

        require(item.existed, "MarketPlace: NFT not existed");

        _distribute(
            item.seller,
            buyer,
            tokenAddress,
            tokenId,
            item.currency,
            item.salePrice
        );

        delete listingPurchasedItems[tokenAddress][tokenId];

        emit Buy(
            tokenId,
            tokenAddress,
            item.currency,
            item.salePrice,
            item.seller,
            buyer
        );
    }

    function openForRent(SellRequest calldata data) public {
        address lender = _msgSender();
        uint256 tokenId = data.tokenId;
        address tokenAddress = data.tokenAddress;

        require(
            tokenAddress.supportsInterface(type(IDerivativeNFT2).interfaceId),
            "Marketplace: Invalid derivative nft2 token"
        );

        require(
            ITimeHelper(tokenAddress).isOpen(tokenId),
            "Marketplace: Derivative nft2 token is expired"
        );

        marketplaceVault.deposit(lender, tokenAddress, data.tokenId);

        listingRentingItems[tokenAddress][tokenId] = ListingRentingItem({
            tokenId: tokenId,
            tokenAddress: tokenAddress,
            currency: data.currency,
            salePrice: data.salePrice,
            lender: lender,
            existed: true
        });

        emit OpenForRent(
            tokenId,
            tokenAddress,
            data.currency,
            data.salePrice,
            lender,
            ITimeHelper(tokenAddress).getOpeningTime(tokenId),
            ITimeHelper(tokenAddress).getClosingTime(tokenId)
        );
    }

    function rent(PaymentRequest calldata payment)
        public
        payable
        virtual
        whenNotPaused
    {
        address borrower = _msgSender();
        uint256 tokenId = payment.tokenId;
        address tokenAddress = payment.tokenAddress;

        ListingRentingItem memory item = listingRentingItems[tokenAddress][
            tokenId
        ];

        require(item.existed, "MarketPlace: NFT not existed");

        _distribute(
            item.lender,
            borrower,
            tokenAddress,
            tokenId,
            item.currency,
            item.salePrice
        );

        delete listingPurchasedItems[tokenAddress][tokenId];

        emit Rent(
            tokenId,
            tokenAddress,
            item.currency,
            item.salePrice,
            item.lender,
            borrower
        );
    }

    function _distribute(
        address seller,
        address payer,
        address tokenAddress,
        uint256 tokenId,
        address currency,
        uint256 salePrice
    ) internal {
        marketplaceVault.withdraw(payer, tokenAddress, tokenId);

        if (tokenAddress.supportsInterface(type(IRoyalty).interfaceId)) {
            (address royaltyReceiver, uint256 royaltyAmount) = IRoyalty(
                tokenAddress
            ).royaltyInfo(tokenId, salePrice);

            if (royaltyReceiver != address(0) && royaltyAmount != 0) {
                // distribute royalty
                _transferPayment(currency, royaltyAmount, tokenAddress);

                // send back to seller
                _transferPayment(currency, salePrice - royaltyAmount, seller);
            } else {
                _transferPayment(currency, salePrice, seller);
            }
        } else {
            _transferPayment(currency, salePrice, seller);
        }
    }

    function _transferPayment(
        address currency,
        uint256 salePrice,
        address to
    ) internal {
        address payer = _msgSender();

        if (currency == address(0)) {
            require(
                msg.value >= salePrice,
                "MarketPlace: Not enough native token"
            );

            (bool success, ) = payable(to).call{value: salePrice}("");
            require(success, "Transfer failed");

            // no refund
            // payable(item.receiver).transfer(msg.value - payment.price - payment.fee);
        } else {
            uint8 decimals = IERC20MetadataUpgradeable(currency).decimals();
            uint256 difference = 18 - decimals;

            uint256 currentBuyTokenBalanceAmount = IERC20Upgradeable(currency)
                .balanceOf(payer);
            uint256 totalBuyTokenAmount = salePrice / 10**difference;

            require(
                currentBuyTokenBalanceAmount >= totalBuyTokenAmount,
                "MarketPlace: not enough buy token"
            );

            if (totalBuyTokenAmount > 0) {
                tokenTransferProxy.transferFrom(
                    currency,
                    payer,
                    to,
                    totalBuyTokenAmount
                );
            }
        }
    }
}
