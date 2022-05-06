// SPDX-License-Identifier: MIT
pragma solidity >=0.5;

import "@klaytn/contracts/token/KIP7/KIP7Token.sol";
import "./libraries/Math.sol";
import "./libraries/UQ112x112.sol";
import "@klaytn/contracts/math/SafeMath.sol";

contract ChimackswapV2Pair is KIP7Token, Math, SafeMath{
  using SafeMath for uint256;
  using UQ112x112 for uint224;

  uint256 constant MINIMUM_LIQUIDITY = 1000;

  address public token0;
  address public token1;

  uint112 private reserve0;
  uint112 private reserve1;

  uint32 private blockTimestampLast;
  uint256 public price0CumulativeLast;
  uint256 public price1CumulativeLast;

  uint256 private unlocked = 1;
  modifier lock() {
    require(unlocked == 1, "ChimackswapV2: LOCKED");
    unlocked = 0;
    _;
    unlocked = 1;
  }
  
  constructor(address _token0, address _token1) KIP7Token("ChimackswapV2 Pair", "CHIMACKV2", 18, 0) public{
    token0 = _token0;
    token1 = _token1;
  }

  function getReserves() public veiw returns (uint112, uint112, uint32){
    return (reserve0, reserve1, 0);
  }

  function mint() public lock {
    (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
    uint256 balance0 = IKIP7(token0).balanceOf(address(this));
    uint256 balance1 = IKIP7(token1).balanceOf(address(this));
    uint256 amount0 = balance0.sub(_reserve0);
    uint256 amount1 = balance1.sub(_reserve1);

    uint256 liquidity;

    if(totalSupply() == 0){
      liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
      _mint(address(0), MINIMUM_LIQUIDITY);
    } else {
      liquidity = Math.min(
        (amount0.mul(totalSupply())).div(_reserve0),
        (amount1.mul(totalSupply())).div(_reserve1)
      );
    }

    require(liquidity > 0);
    
    _mint(msg.sender, liquidity);

  }
  
  function burn() public lock{
    uint256 balance0 = IKIP7(token0).balanceOf(address(this));
    uint256 balance1 = IKIP7(token1).balanceOf(address(this));
    uint256 liquidity = balanceOf(msg.sender);

    uint256 amount0 = (liquidity.mul(balance0)).div(totalSupply());
    uint256 amount1 = (liquidity.mul(balance1)).div(totalSupply());

    require(amount > 0 && amount1 > 0, "Insufficient liquidity burned");

    _burn(msg.sender, liquidity);

    _safeTransfer(token0, msg.sender, amount0);
    _safeTrasnfer(token1, msg.sender, amount1);

    balance0 = IKIP7(token0).balanceOf(address(this));
    balance1 = IKIP7(token1).balanceOf(address(this));

    _update(balance0, balance1);
  }

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to
  ) public lock{
    require(amount0out > 0 || amount1Out > 0, "Insufficient Output Amount");

    (uint112 reserve0_, uint112 reserve1_, ) = getReserves();

    require(amount0Out <= reserve0_ && amount1Out <= reserve1, "Insufficient Liquidity");

    uint256 balance0 = IKIP7(token0).balanceOf(address(this)).sub(amount0Out);
    uint256 balance1 = IKIP7(token1).balanceOf(address(this)).sub(amount1Out);

    require(balance0.mul(balance1) >= uint256(reserve0_).mul(uint256(reserve1_)), "Invalid K");

    _update(balance0, balance1, reserve0_, reserve1_);

    if(amount0Out > 0) _safeTransfer(token0, to, amount0Out);
    if(amount1Out > 0) _safeTransfer(token1, to, amount1Out);

  }

  function _update(uint256 balance0, uint256 balance1, uint112 reserve0_, uint112 reserve1_) private {
    require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "Balance Overflow");

    uint32 timeElapsed = uint32(block.timestamp) - blockTimestampLast;
    if(timeElapsed > 0 && reserve0_ > 0 && reserve1_ > 0) {
      price0CumulativeLast += uint256(UQ112x112.encode(reserve1_).uqdiv(reserve0_)) * timeElapsed;
      price1CumulativeLast += uint256(UQ112x112.encode(reserve0_).uqdiv(reserve1_)) * timeElapsed;
    }
    
    
    reserve0 = uint112(balance0);
    reserve1 = uint112(balance1);
    blockTimestampLast = uint32(block.timestamp);
  }

  function _safeTransfer(
    address token,
    address to,
    uint256 value
  ) private {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSignature("transfer(address,uint256)", to, value)
    );
    if(!success || (data.length != 0 && !abi.decode(data, (bool)))) revert("Transfer failed");
  }
}