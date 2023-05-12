// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

interface ISwapFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface ISwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

contract FeeController is Ownable2StepUpgradeable {
    mapping(bytes32 => uint256) internal _fees;

    ISwapRouter internal _router;
    IERC20Upgradeable internal _token;
    address internal _feeReceiver;

    function initialize(
        address router_,
        address token_,
        address feeReceiver_
    ) public initializer {
        __FeeController_init(router_, token_, feeReceiver_);
    }

    function __FeeController_init_unchained(
        address router_,
        address token_,
        address feeReceiver_
    ) internal onlyInitializing {
        _router = ISwapRouter(router_);
        _token = IERC20Upgradeable(token_);
        _feeReceiver = feeReceiver_;
    }

    function __FeeController_init(
        address router_,
        address token_,
        address feeReceiver_
    ) internal onlyInitializing {
        __Ownable2Step_init_unchained();
        __FeeController_init_unchained(router_, token_, feeReceiver_);
    }

    function setFeeOf(bytes32 method, uint256 amount) public onlyOwner {
        _fees[method] = amount;
    }

    function router() public view returns (address) {
        return address(_router);
    }

    function token() public view returns (address) {
        return address(_token);
    }

    function feeReceiver() public view returns (address) {
        return _feeReceiver;
    }

    function getNativePair() public view returns (address) {
        if (address(_router) == address(0)) return address(0);
        
        ISwapFactory factory = ISwapFactory(_router.factory());
        return factory.getPair(address(_token), _router.WETH());
    }

    function systemFeeOf(bytes32 method) public view returns (uint256) {
        return _fees[method];
    }

    /**
     * fee in native token
     */
    function feeOf(bytes32 method) public view returns (uint256) {
        // convert DNFT to BNB
        uint256 systemFee = _fees[method];
        // native fee
        if (address(_router) == address(0) && address(_token) == address(0)) return systemFee;

        if (address(_router) == address(0)) return 0;
        if (!AddressUpgradeable.isContract(address(_router))) return 0;
        if (systemFee == 0) return 0;

        address[] memory paths = new address[](2);
        paths[1] = address(_token);
        paths[0] = _router.WETH();

        uint256[] memory amounts = _router.getAmountsIn(systemFee, paths);

        //  PancakeLibrary.getAmountsOut(
        //     factory,
        //     msg.value,
        //     path
        // );
        return amounts[0];
    }

    function deposit() public payable {
        uint256 deadline = block.timestamp + 1 days;
        address[] memory paths = new address[](2);
        paths[0] = _router.WETH();
        paths[1] = address(_token);

        if (_feeReceiver == address(0)) return; // ignore

        _router.swapExactETHForTokens{value: msg.value}(
            0,
            paths,
            _feeReceiver,
            deadline
        );

        // _token.transfer(_feeReceiver, _token.balanceOf(address(this)));
    }
}
