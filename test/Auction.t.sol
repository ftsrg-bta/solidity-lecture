// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Auction} from "../src/Auction.sol";
import {Attacker} from "../src/Attacker.sol";

contract AuctionTest is Test {
    Auction auction;

    address owner = makeAddr("owner");
    address bidder1 = makeAddr("bidder1");
    address bidder2 = makeAddr("bidder2");
    address attacker = makeAddr("attacker");

    function setUp() public {
        vm.prank(owner);
        auction = new Auction();
    }

    function test_BidUpdatesHighestBid() public {
        // Arrange
        uint256 bid = 1 ether;

        // Act
        hoax(bidder1);
        auction.bid{value: bid}();

        // Assert
        assertEq(auction.highestBidder(), bidder1, "Highest bidder address should be bidder1's");
        assertEq(auction.highestBid(), bid, "Highest bid amount should be bidder1's");
    }

    function test_BidCanOutbidPrevious() public {
        // Arrange
        uint256 bid1 = 1 ether;
        uint256 bid2 = 2 ether;
        hoax(bidder1);
        auction.bid{value: bid1}();

        // Act
        hoax(bidder2);
        auction.bid{value: bid2}();

        // Assert
        assertEq(auction.highestBidder(), bidder2, "Highest bidder address should be bidder2's");
        assertEq(auction.highestBid(), bid2, "Highest bid amount should be bidder2's");
        assertEq(auction.pendingReturns(bidder1), bid1, "bidder1 should have a pending return of their full bid amount");
    }

    function test_BidEmitsEvent() public {
        // Arrange
        uint256 bid = 1 ether;

        // Act & Assert
        hoax(bidder1);
        vm.expectEmit();
        emit Auction.BidPlaced(bidder1, bid);
        auction.bid{value: bid}();
    }

    function test_BidCannotBeTooLow() public {
        // Arrange
        uint256 bid1 = 2 ether;
        uint256 bid2 = 1 ether;
        hoax(bidder1);
        auction.bid{value: bid1}();

        // Act & Assert
        hoax(bidder2);
        vm.expectRevert(Auction.BidTooLow.selector);
        auction.bid{value: bid2}();
    }

    function test_BidCannotBeTheSame() public {
        // Arrange
        uint256 bid1 = 1 ether;
        uint256 bid2 = 1 ether;
        hoax(bidder1);
        auction.bid{value: bid1}();

        // Act & Assert
        hoax(bidder2);
        vm.expectRevert(Auction.BidTooLow.selector);
        auction.bid{value: bid2}();
    }

    function test_BidAfterEnd() public {
        // Arrange
        uint256 bid1 = 1 ether;
        uint256 bid2 = 2 ether;
        hoax(bidder1);
        auction.bid{value: bid1}();
        vm.prank(owner);
        auction.endAuction();

        // Act & Assert
        hoax(bidder2);
        vm.expectRevert(abi.encodeWithSelector(Auction.NotInPhase.selector, Auction.AuctionPhase.BIDDING));
        auction.bid{value: bid2}();
    }

    function test_WithdrawReturnsFunds() public {
        // Arrange
        uint256 bid1 = 1 ether;
        uint256 bid2 = 2 ether;
        hoax(bidder1);
        auction.bid{value: bid1}();
        hoax(bidder2);
        auction.bid{value: bid2}();

        // Act
        uint256 balanceBefore = bidder1.balance;
        vm.prank(bidder1);
        auction.withdraw();
        uint256 balanceAfter = bidder1.balance;

        // Assert
        uint256 balanceDiff = balanceAfter - balanceBefore;
        assertEq(balanceDiff, bid1, "bidder1 should have been fully refunded for their bid");
        assertEq(auction.pendingReturns(bidder1), 0, "bidder1's pending returns should have been zeroed out");
    }

    function test_WithdrawWorksAfterEnd() public {
        // Arrange
        uint256 bid1 = 1 ether;
        uint256 bid2 = 2 ether;
        hoax(bidder1);
        auction.bid{value: bid1}();
        hoax(bidder2);
        auction.bid{value: bid2}();
        vm.prank(owner);
        auction.endAuction();

        // Act
        uint256 balanceBefore = bidder1.balance;
        vm.prank(bidder1);
        auction.withdraw();
        uint256 balanceAfter = bidder1.balance;

        // Assert
        uint256 balanceDiff = balanceAfter - balanceBefore;
        assertEq(balanceDiff, bid1, "bidder1 should have been fully refunded for their bid");
        assertEq(auction.pendingReturns(bidder1), 0, "bidder1's pending returns should have been zeroed out");
    }

    function test_WithdrawFailsIfNothingToWithdraw() public {
        // Arrange
        uint256 bid = 1 ether;
        hoax(bidder1);
        auction.bid{value: bid}();

        // Act & Assert
        vm.prank(bidder2);
        vm.expectRevert(Auction.NothingToWithdraw.selector);
        auction.withdraw();
    }

    function test_EndAuction() public {
        // Arrange
        uint256 bid1 = 1 ether;
        uint256 bid2 = 2 ether;
        hoax(bidder1);
        auction.bid{value: bid1}();
        hoax(bidder2);
        auction.bid{value: bid2}();

        // Act
        uint256 balanceBefore = owner.balance;
        vm.prank(owner);
        auction.endAuction();
        uint256 balanceAfter = owner.balance;

        // Assert
        uint256 balanceDiff = balanceAfter - balanceBefore;
        assertEq(balanceDiff, bid2, "owner should have received winning bidder2's funds");
        assertEq(
            uint256(auction.phase()), uint256(Auction.AuctionPhase.ENDED), "Auction phase should have become ENDED"
        );
    }

    function test_EndAuctionEmitsEvent() public {
        // Arrange
        uint256 bid = 1 ether;
        hoax(bidder1);
        auction.bid{value: bid}();

        // Act & Assert
        vm.prank(owner);
        vm.expectEmit();
        emit Auction.AuctionEnded(bidder1, bid);
        auction.endAuction();
    }

    function test_EndAuctionByNotOwner() public {
        // Arrange
        uint256 bid1 = 1 ether;
        uint256 bid2 = 2 ether;
        hoax(bidder1);
        auction.bid{value: bid1}();
        hoax(bidder2);
        auction.bid{value: bid2}();

        // Act & Assert
        vm.prank(bidder1);
        vm.expectRevert(Auction.OnlyOwner.selector);
        auction.endAuction();
    }

    function test_EndAuctionAfterEnd() public {
        // Arrange
        uint256 bid1 = 1 ether;
        uint256 bid2 = 2 ether;
        hoax(bidder1);
        auction.bid{value: bid1}();
        hoax(bidder2);
        auction.bid{value: bid2}();
        vm.prank(owner);
        auction.endAuction();

        // Act & Assert
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Auction.NotInPhase.selector, Auction.AuctionPhase.BIDDING));
        auction.endAuction();
    }
}
