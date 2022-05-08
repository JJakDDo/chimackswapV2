// SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.6;

import "./interfaces/IChimackswapV2Pair.sol";
import "./interfaces/IChimackswapV2Factory.sol";

library ChimackswapV2Library {
  function getReserves(
    address factoryAddress,
    address tokenA,
    address tokenB
  ) public returns (uint256 reserveA, uint256 reserveB) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1, ) = IChimackswapV2Pair(pairFor(factoryAddress, token0, token1)).getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  function sortTokens(
    address tokenA, 
    address tokenB) internal pure returns(address token0, address token1) {
      return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

  function pairFor(
    address factoryAddress,
    address tokenA,
    address tokenB
  ) internal pure returns (address pairAddress){
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pairAddress = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"ff",
              factoryAddress,
              keccak256(abi.encodePacked(token0, token1)),
              hex"049f60b9e01e08c8f30809369bea021451544d751aa028da0bc80c726d334c6c"
            )
          )
        ) 
      ) 
    );
  }

  function quote(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) public pure returns (uint256 amountOut) {
    if(amountIn == 0) revert("Insufficient amount");
    if(reserveIn == 0 || reserveOut == 0) revert("Insufficient liquidity");

    return (amountIn * reserveOut) / reserveIn;
  }

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) public pure returns (uint256) {
    if(amountIn == 0) revert("Insufficient amount");
    if(reserveIn == 0 || reserveOut == 0) revert("Insufficient liquidity");

    uint256 amountInWithFee = amountIn * 997;
    uint256 numerator = amountInWithFee * reserveOut;
    uint256 denominator = (reserveIn * 1000) + amountInWithFee;

    return numerator / denominator;
  }

  function getAmountsOut(
    address factory,
    uint256 amountIn,
    address[] memory path
  ) public returns (uint256[] memory) {
    if(path.length < 2) revert("Invalid path");
    uint256[] memory amounts = new uint256[](path.length);
    amounts[0] = amountIn;

    for(uint256 i; i < path.length - 1; i++){
      (uint256 reserve0, uint256 reserve1) = getReserves(
        factory,
        path[i],
        path[i+1]
      );
      amounts[i+1] = getAmountOut(amounts[i], reserve0, reserve1);
    }
    return amounts;
  }
}