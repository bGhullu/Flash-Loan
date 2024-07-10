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
