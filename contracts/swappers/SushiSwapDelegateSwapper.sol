// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
import "../libraries/BoringMath.sol";
import "../libraries/Ownable.sol";
import "../external/SushiSwapFactory.sol";
import "../interfaces/IVault.sol";

contract SushiSwapDelegateSwapper {
    using BoringMath for uint256;

    // Keep at the top, these are members from Pair that will be available due to delegatecall
    IVault public vault;
    address public tokenA;
    address public tokenB;

    IUniswapV2Factory public factory;

    constructor(IUniswapV2Factory factory_) public {
        factory = factory_;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    event Debug(address val);

    function swap(SushiSwapDelegateSwapper swapper, address from, address to, uint256 amountFrom, uint256 amountToMin) public returns (uint256) {
        UniswapV2Pair pair = UniswapV2Pair(swapper.factory().getPair(from, to));

        emit Debug(address(vault));
        emit Debug(address(pair));
        emit Debug(address(from));
        vault.transfer(from, address(pair), amountFrom);

        uint256 reserve0;
        uint256 reserve1;
        (reserve0, reserve1,) = pair.getReserves();
        uint256 amountTo;
        if (pair.token0() == from) {
            amountTo = getAmountOut(amountFrom, reserve0, reserve1);
            require(amountTo >= amountToMin, 'SushiSwapClosedSwapper: return not enough');
            pair.swap(0, amountTo, address(vault), new bytes(0));
        } else {
            amountTo = getAmountOut(amountFrom, reserve1, reserve0);
            require(amountTo >= amountToMin, 'SushiSwapClosedSwapper: return not enough');
            pair.swap(amountTo, 0, address(vault), new bytes(0));
        }
        return amountTo;
    }
}
