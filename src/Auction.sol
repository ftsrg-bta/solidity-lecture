// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

contract Auction {
    address public highestBidder;
    uint256 public highestBid;
    mapping(address bidder => uint256 bidAmount) public pendingReturns;

    event BidPlaced(address indexed bidder, uint256 amount);

    error BidTooLow();
    error NothingToWithdraw();
    error TransferFailed();

    function bid() external payable {
        if (msg.value <= highestBid) revert BidTooLow();

        pendingReturns[highestBidder] += highestBid;

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit BidPlaced(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        if (amount == 0) revert NothingToWithdraw();

        pendingReturns[msg.sender] = 0;

        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed();
    }
}
