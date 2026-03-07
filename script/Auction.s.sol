// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Auction} from "../src/Auction.sol";

contract AuctionScript is Script {
    function run() public {
        vm.startBroadcast();
        new Auction();
        vm.stopBroadcast();
    }
}
