// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Auction} from "../src/Auction.sol";
import {Attacker} from "../src/Attacker.sol";

contract AuctionReentrancyTest is Test {
    function test_WithdrawIsNotReentrant() public {
        // Arrange
        address owner = makeAddr("owner");
        address bidder = makeAddr("bidder1");
        address attacker = makeAddr("attackerEOA");
        //
        vm.prank(owner);
        Auction auction = new Auction();
        //
        hoax(bidder);
        auction.bid{value: 1 ether}();
        //
        uint256 attackerBid = 2 ether;
        vm.prank(attacker);
        Attacker attackerContract = new Attacker(address(auction));
        hoax(attacker);
        attackerContract.placeBid{value: attackerBid}();
        //
        hoax(bidder);
        auction.bid{value: 3 ether}();

        // Act & Assert
        uint256 balanceBefore = address(attackerContract).balance;
        vm.prank(attacker);
        (bool success,) = address(attackerContract).call(abi.encodeWithSignature("attack()"));
        uint256 balanceAfter = address(attackerContract).balance;

        // Assert
        uint256 balanceDiff = balanceAfter - balanceBefore;
        if (success) {
            assertEq(balanceDiff, attackerBid, "Attacker contract should only have been refunded its bid amount");
        } else {
            assertEq(balanceDiff, 0, "Attacker contract should not have received any funds");
        }
    }
}
