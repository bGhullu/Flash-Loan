//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "hardhat/console.sol";

import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {PoolAddress} from "../library/PoolAddress.sol";

contract FlashLoan {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IUniswapV2Router02 constant PANCAKESWAPV2 =
        IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    ISwapRouter constant PANCAKESWAPV3 =
        ISwapRouter(0x1b81D678ffb9C0263b24A97847620C99d213eB14);
    IERC20 private immutable token0;
    IERC20 private immutable token1;
    uint24 private immutable fee;
    IUniswapV3Pool private immutable pool;

    address private constant DEPLOYER_ADDRESS =
        0x41ff9AA7e16B8B1a8a8dc4f0eFacd93D02d071c9;

    struct FlashCallbackData {
        uint amount0;
        uint amount1;
        address caller;
        address[2] path;
        uint8[3] exchangeRoute;
        uint24 fee;
    }

    constructor(address _token0, address _token1, uint24 _fee) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        fee = _fee;
        pool = IUniswapV3Pool(getPool(_token0, _token1, _fee));
    }

    function flashLoanRequest(
        address[2] memory _path,
        uint256 _amount0,
        uint256 _amount1,
        uint24 _fee,
        uint8[3] memory _exchangeRoute
    ) external {
        bytes memory data = abi.encode(
            FlashCallbackData({
                amount0: _amount0,
                amount1: _amount1,
                caller: msg.sender,
                path: _path,
                exchangeRoute: _exchangeRoute,
                fee: _fee
            })
        );
        console.log("");
        console.log("FLASHLOAN POOL ADDRESS:", address(pool));
        IUniswapV3Pool(pool).flash(address(this), _amount0, _amount1, data);
    }

    function pancakeV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external {
        require(msg.sender == address(pool), "Not Authorized!");
        FlashCallbackData memory decoded = abi.decode(
            data,
            (FlashCallbackData)
        );

        //Initialize

        IERC20 baseToken = (fee0 > 0) ? token0 : token1;
        uint256 acquiredAmount = (fee0 > 0) ? decoded.amount0 : decoded.amount1;
        console.log("Fee0: ", fee0);
        console.log("Fee1:", fee1);
        console.log("BaseToken: ", address(baseToken));
        console.log("Borrow: ", acquiredAmount);

        // Trade 1

        acquiredAmount = place_swap(
            acquiredAmount,
            [address(baseToken), decoded.path[0]],
            decoded.exchangeRoute[0],
            decoded.fee
        );
        console.log("Swap1 Token:", decoded.path[0]);
        console.log("Swap1 Amount:", acquiredAmount);

        // Trade 2
        acquiredAmount = place_swap(
            acquiredAmount,
            [decoded.path[1], address(baseToken)],
            decoded.exchangeRoute[2],
            decoded.fee
        );
        console.log("Swap3 Token:", address(baseToken));
        console.log("Swap3 Amount:", acquiredAmount);

        // Trade 3
        acquiredAmount = place_swap(
            acquiredAmount,
            [decoded.path[0], decoded.path[1]],
            decoded.exchangeRoute[1],
            decoded.fee
        );
        console.log("Swap2 Token:", decoded.path[1]);
        console.log("Swap2 Amount:", acquiredAmount);

        // Repay the Flashloan
    }

    function place_swap(
        uint256 _amountIn,
        address[2] memory _tokenPath,
        uint8 _route,
        uint24 _v3_fee
    ) private returns (uint256) {
        //Initialize
        uint256 deadline = block.timestamp + 30;
        uint256 swap_amount_out = 0;
        address[] memory path = new address[](2);
        path[0] = _tokenPath[0];
        path[1] = _tokenPath[1];

        // Handle for UniswapV2
        if (_route == 0) {
            TransferHelper.safeApprove(
                _tokenPath[0],
                address(PANCAKESWAPV2),
                _amountIn
            );
            swap_amount_out = PANCAKESWAPV2.swapExactTokensForTokens({
                amountIn: _amountIn,
                amountOutMin: 0,
                path: path,
                to: address(this),
                deadline: deadline
            })[1];
        } else if (_route == 1) {
            TransferHelper.safeApprove(
                _tokenPath[0],
                address(PANCAKESWAPV3),
                _amountIn
            );
            uint256 amountOutMinimum = 0;
            uint160 sqrtPriceLimitX96 = 0;
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                .ExactInputSingleParams({
                    tokenIn: _tokenPath[0],
                    tokenOut: _tokenPath[1],
                    fee: _v3_fee,
                    recipient: address(this),
                    deadline: deadline,
                    amountIn: _amountIn,
                    amountOutMinimum: amountOutMinimum,
                    sqrtPriceLimitX96: sqrtPriceLimitX96
                });
            swap_amount_out = PANCAKESWAPV3.exactInputSingle(params);
        }

        return swap_amount_out;
    }

    function getPool(
        address _token0,
        address _token1,
        uint24 _fee
    ) internal pure returns (address) {
        PoolAddress.PoolKey memory key = PoolAddress.getPoolKey(
            _token0,
            _token1,
            _fee
        );
        return PoolAddress.computeAddress(DEPLOYER_ADDRESS, key);
    }
}
