// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import "../src/Perpetual.sol";

contract CounterScript is Script {

    Perpetual public perp = Perpetual(0x8ac4059F12cDf521D94DBd3bfB3981709Dd345cc);
    function setUp() public {}


    uint256 userPk = 0x3c3c22a7ca08ec63fa8f9f8db2d73a2f71431a94ea88956a4dc0c84d06be970e;
    address user = 0x7735cE49c065d175D5fC39CF030586575b5194c5;
    function run() public {
        uint256 pk = 0xcaf1088ee4150e04fd0b6a9025c9d8fa3c75f64d8c299dccb76e5867dce9ac63;
        address deployer =0x6942048b8E92e75618ffD6d49a626B00f4cd0E9c;
        vm.startBroadcast(pk);
            new Perpetual();

        vm.stopBroadcast();
    }

    function faucet() public {

        vm.broadcast(userPk);
            perp.faucet();



    }
    function bid() public {
        vm.broadcast(userPk);
            perp.openPosition(1000*10**18, 1000000*10**18, true, 1);
    }

    function close() public {
        vm.startBroadcast(userPk);
            perp.closePosition(perp.balanceOfNotional(user, 1), 1);
        vm.stopBroadcast();
    }
}
