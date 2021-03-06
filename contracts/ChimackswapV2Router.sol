// SPDX-License-Identifier: MIT
pragma solidity >=0.5;

import "./ChimackswapV2Pair.sol";
import "./interfaces/IChimackswapV2Pair.sol";
import "./interfaces/IChimackswapV2Factory.sol";
import "./ChimackswapV2Library.sol";

contract ChimackswapV2Router {
  IChimackswapV2Factory factory;

  constructor(address factoryAddress) public {
    factory = IChimackswapV2Factory(factoryAddress);
  }

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to
  ) public returns (
    uint256 amountA,
    uint256 amountB,
    uint256 liquidity
  ) {
    if(factory.pairs(tokenA, tokenB) == address(0)){
      factory.createPair(tokenA, tokenB);
    }

    (amountA, amountB) = _calculateLiquidity(
      tokenA,
      tokenB,
      amountADesired,
      amountBDesired,
      amountAMin,
      amountBMin
    );
    address pairAddress = ChimackswapV2Library.pairFor(
      address(factory),
      tokenA,
      tokenB
    );

    _safeTransferFrom(tokenA, msg.sender, pairAddress, amountA);
    _safeTransferFrom(tokenB, msg.sender, pairAddress, amountB);
    liquidity = IChimackswapV2Pair(pairAddress).mint(to);
  }

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to 
  ) public returns (uint256 amountA, uint256 amountB){
    address pair = ChimackswapV2Library.pairFor(
      address(factory),
      tokenA,
      tokenB
    );
    IChimackswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity);
    (amountA, amountB) = IChimackswapV2Pair(pair).burn(to);
    if(amountA < amountAMin) revert("Insufficient A amount");
    if(amountA < amountBMin) revert("Insufficient B amount");
  }

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to
  ) public returns (uint256[] memory amounts) {
    amounts = ChimackswapV2Library.getAmountsOut(
      address(factory),
      amountIn,
      path
    );
    if(amounts[amounts.length - 1] < amountOutMin) revert("Insufficient output amount");
    _safeTransferFrom(
      path[0], 
      msg.sender,
      ChimackswapV2Library.pairFor(address(factory), path[0], path[1]),
      amounts[0]
    );
    _swap(amounts, path, to);
  }

  function _caluclateLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDeisred,
    uint256 amountAMin,
    uint256 amountBMin
  ) internal returns (uint256 amountA, uint256 amountB) {
    (uint256 reserveA, uint256 reserveB) = ChimackswapV2Library.getReserves(
      address(factory), tokenA, tokenB);
    
    if(reserveA == 0 && reserveB == 0){
      (amountA, amountB) = (amountADesired, amountBDeisred);
    } else {
      uint256 amountBOptimal = ChimackswapV2Library.quote(
        amountADesired,
        reserveA,
        reserveB
      );
      if(amountBOptimal <= amountBDeisred){
        if(amountBOptimal <= amountBMin) revert("Insufficient B amount");
        (amountA, amountB) = (amountADesired, amountBOptimal);
      } else {
        uint256 amountAOptimal = ChimackswapV2Library.quote(
          amountBDesired,
          reserveB,
          reserveA
        );
        assert(amountAOptimal <= amountADesired);

        if(amountAOptimal <= amountAMin) revert("Insufficient A amount");
        (amountA, amountB) = (amountAOptimal, amountBDeisred);
      }
    }
  }

  function _swap(
    uint256[] memory amounts,
    address[] memory path,
    address to_
  ) internal {
    for(uint256 i; i < path.length - 1; i++){
      (address input, address output) = (path[i], path[i+1]);
      (address token0, ) = ChimackswapV2Library.sortTokens(input, output);
      uint256 amountOut = amounts[i+1];
      (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uihnt256(0));

      address to = i < path.length - 2 ? ChimackswapV2Library.pairFor(address(factory), output, path[i+2]) : to_;

      IChimackswapV2Pair(ChimackswapV2Library.pairFor(address(factory), input, output)).swap(amount0Out, amount1Out, to, "");
    }
  }

  function _safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) private {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSignature(
        "transferFrom(address,address,uint256)",
        from,
        to,
        value
        )
     );
    if((!success || (data.length != 0 && !abi.decode(data, (bool))))) revert("Safe transfer failed");
  }
}