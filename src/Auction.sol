// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

contract Auction {
    address public highestBidder;
    uint256 public highestBid;

    error BidTooLow();

    function bid() external payable {
        if (msg.value <= highestBid) revert BidTooLow();

        highestBidder = msg.sender;
        highestBid = msg.value;
    }
}
