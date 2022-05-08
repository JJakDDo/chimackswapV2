// SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.6;

interface IChimackswapV2Factory {
    function pairs(address, address) external pure returns (address);

    function createPair(address, address) external returns (address);
}