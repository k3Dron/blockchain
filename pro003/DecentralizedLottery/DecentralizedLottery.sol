// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DecentralizedLottery is ReentrancyGuard {
    address public owner;
    uint256 public ticketPrice = 0.01 ether;
    uint256 public currentRound;
    uint256 public startTime;
    uint256 public endTime;

    address[] public participants;

    event LotteryStarted(uint256 round, uint256 startTime, uint256 endTime);
    event TicketPurchased(address indexed participant, uint256 round);
    event WinnerDeclared(uint256 round, address indexed winner, uint256 prize);

    constructor() {
        owner = msg.sender;
        startNewRound();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier duringLottery() {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Lottery is not active"
        );
        _;
    }

    modifier afterLottery() {
        require(block.timestamp > endTime, "Lottery is still active");
        _;
    }

    function startNewRound() internal {
        currentRound++;
        startTime = block.timestamp - (block.timestamp % 1 days);
        endTime = startTime + 22 hours; 
        delete participants;

        emit LotteryStarted(currentRound, startTime, endTime);
    }

    function buyTicket() external payable duringLottery nonReentrant {
        require(msg.value == ticketPrice, "Incorrect ticket price");
        participants.push(msg.sender);
        emit TicketPurchased(msg.sender, currentRound);
    }

    function declareWinner() external onlyOwner afterLottery nonReentrant {
        require(participants.length > 0, "No participants in this round");
        uint256 randomIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.difficulty, participants))
        ) % participants.length;
        address winner = participants[randomIndex];
        uint256 prize = address(this).balance;
        (bool success, ) = payable(winner).call{value: prize}("");
        require(success, "Transfer to winner failed");
        emit WinnerDeclared(currentRound, winner, prize);
        startNewRound();
    }
}