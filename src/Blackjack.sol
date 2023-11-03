// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Token} from "./token.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Blackjack is VRFConsumerBaseV2 {
    //////////////
    /// Errors ///
    //////////////

    error NotEnoughEther();
    error TransferedFailed();
    error MustBeGreaterThanZero();
    error NotEnoughTokens();
    error NotInGame();

    struct Player {
        uint256[] cards;
        uint256 sum;
        bool inGame;
        uint256 amount;
    }

    ///////////////////////
    /// State Variables ///
    ///////////////////////
    mapping(address => Player) private players;
    mapping(address => uint256) private ownerCardsByUser;

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    Token private immutable token;
    uint256 private constant TOKEN_PRICE = 0.01 ether;

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    uint256 private recentRandomNumber;

    modifier onlyWhenInGame(address player) {
        if (!players[player].inGame) {
            revert NotInGame();
        }
        _;
    }

    constructor(
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        token = new Token();
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
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

    function playGame(uint256 amount) external {
        if (token.balanceOf(msg.sender) < amount) {
            revert NotEnoughTokens();
        }
        bool ok = token.transferFrom(msg.sender, address(this), amount);
        if (!ok) {
            revert TransferedFailed();
        }
        players[msg.sender].inGame = true;
        deal();
        deal();
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        ownerCardsByUser[msg.sender] = recentRandomNumber;
    }

    function deal() public onlyWhenInGame(msg.sender) {
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        players[msg.sender].cards.push(recentRandomNumber);
        players[msg.sender].sum += recentRandomNumber;
        _checkIfBust(msg.sender);
    }

    function hit() external onlyWhenInGame(msg.sender){
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        players[msg.sender].inGame = false;
        if (ownerCardsByUser[msg.sender] + recentRandomNumber > players[msg.sender].sum) {
            bool ok = token.transfer(msg.sender, (players[msg.sender].amount * 150) / 100);
        }
    }

    function _checkIfBust(address player) internal {
        Player memory p = players[player];
        if (p.sum >= 21) {
            players[player].inGame = false;
        }
        if (p.sum == 21) {
            bool ok = token.transfer(player, (p.amount * 150) / 100);
            if (!ok) {
                revert TransferedFailed();
            }
        }
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        recentRandomNumber = randomWords[0] % 14;
    }

    function getRecentRandomNumber() external view returns (uint256) {
        return recentRandomNumber;
    }

    function getToken() external view returns (Token) {
        return token;
    }

    function getPlayer(address player) external view returns (Player memory) {
        return players[player];
    }

    function getOwnerCardsByUser(address player) external view returns (uint) {
        return ownerCardsByUser[player];
    }
}
