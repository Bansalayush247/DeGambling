// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Token} from "./token.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


contract Blackjack {

    //////////////
    /// Errors ///
    //////////////

    error NotEnoughEther();
    error TransferedFailed();
    error MustBeGreaterThanZero();
    error NotEnoughTokens();

    ///////////////////////
    /// State Variables ///
    ///////////////////////
    Token private immutable token;
    uint256 private constant TOKEN_PRICE = 0.01 ether;

    constructor(address tokenAddress) {
        token = Token(tokenAddress);
    }

    function buyTokens(uint256 amountOfTokens) external payable {
        if (amountOfTokens == 0) {
            revert MustBeGreaterThanZero();
        }
        if (msg.value < 0.01 ether * amountOfTokens) {
            revert NotEnoughEther();
        }
        bool ok = token.transfer(msg.sender, amountOfTokens);
        if (!ok) {
            revert TransferedFailed();
        }
    }

    function sellTokens(uint256 amountOfTokens) external {
        if (amountOfTokens == 0) {
            revert MustBeGreaterThanZero();
        }
        if (token.balanceOf(msg.sender) < amountOfTokens) {
            revert NotEnoughTokens();
        }
        bool ok = token.transferFrom(msg.sender, address(this), amountOfTokens);
        if (!ok) {
            revert TransferedFailed();
        }
    }
}