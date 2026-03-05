// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

contract Auction is ReentrancyGuardTransient {
    enum AuctionPhase {
        BIDDING,
        ENDED
    }

    address public owner;
    AuctionPhase public phase;

    address public highestBidder;
    uint256 public highestBid;

    mapping(address bidder => uint256 bidAmount) public pendingReturns;

    event BidPlaced(address indexed bidder, uint256 amount);
    event AuctionEnded(address indexed winner, uint256 amount);

    error BidTooLow();
    error NothingToWithdraw();
    error TransferFailed();
    error OnlyOwner();
    error NotInPhase(AuctionPhase phase);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier onlyDuring(AuctionPhase _phase) {
        if (phase != _phase) revert NotInPhase(_phase);
        _;
    }

    function bid() external payable onlyDuring(AuctionPhase.BIDDING) {
        if (msg.value <= highestBid) revert BidTooLow();

        pendingReturns[highestBidder] += highestBid;

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit BidPlaced(msg.sender, msg.value);
    }

    function withdraw() external nonReentrant {
        uint256 amount = pendingReturns[msg.sender];
        if (amount == 0) revert NothingToWithdraw();

        pendingReturns[msg.sender] = 0;

        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    function endAuction() external onlyOwner onlyDuring(AuctionPhase.BIDDING) {
        phase = AuctionPhase.ENDED;

        (bool success,) = owner.call{value: highestBid}("");
        if (!success) revert TransferFailed();

        emit AuctionEnded(highestBidder, highestBid);
    }
}
