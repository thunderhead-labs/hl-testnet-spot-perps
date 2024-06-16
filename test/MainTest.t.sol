// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";
import "../src/SystemOracle.sol";
import "../src/USDC.sol";
import "../src/Perpetual.sol";

contract MainTest is Test {
    SystemOracle public oracle = SystemOracle(0x1111111111111111111111111111111111111111);
    address oracleOwner = 0x2222222222222222222222222222222222222222;
    USDC public usdc;
    Perpetual public perp;

    address user = 0x1111111111111111111111111111111111111112;
    function setUp() public {
        // uint256 hlFork = vm.createFork("https://api.hyperliquid-testnet.xyz/evm");
        // vm.selectFork(hlFork);
        console.log("block number", block.number);
        // vm.roll(866320);

        SystemOracle tempOracle = new SystemOracle();


        vm.etch(address(oracle), address(tempOracle).code);

        perp = new Perpetual();
        usdc = USDC(perp.usdc());
        
        vm.prank(user);
            perp.faucet();
    }

    function test_long() public {
        uint256[] memory pxs = new uint256[](100);
        pxs[0] = 1000;
        vm.prank(oracleOwner);
            oracle.setValues(block.number, pxs, pxs);
        

        vm.prank(user);
            perp.openPosition(1000*10**18, 5000*10**18, true, 0);


        pxs[0] = 2000;

        vm.prank(oracleOwner);
            oracle.setValues(block.number, pxs, pxs);

        require(perp.getPositionValue(user, 0) == 10000*10**18, "position value incorrect");

        require(perp.getPositionPnl(user, 0) == 5000*10**18, "position value incorrect");

        vm.startPrank(user);
            perp.closePosition(perp.balanceOfNotional(user, 0), 0);
        vm.stopPrank();

    }

    function test_short() public {
        uint256[] memory pxs = new uint256[](100);
        pxs[0] = 1000;
        vm.prank(oracleOwner);
            oracle.setValues(block.number, pxs, pxs);

        vm.prank(user);
            perp.openPosition(1000*10**18, 5000*10**18, false, 0);
    
        pxs[0] = 800;

        vm.prank(oracleOwner);
            oracle.setValues(block.number, pxs, pxs);

        require(perp.getPositionValue(user, 0) == 4000*10**18, "position value incorrect");

        require(perp.getPositionPnl(user, 0) == 1000*10**18, "pnl incorrect");

        vm.startPrank(user);
            perp.closePosition(perp.balanceOfNotional(user, 0), 0);
        vm.stopPrank();
    }

    function test_liquidateShort() public {
        uint256[] memory pxs = new uint256[](100);
        pxs[0] = 1000;
        vm.prank(oracleOwner);
            oracle.setValues(block.number, pxs, pxs);

        vm.prank(user);
            perp.openPosition(1000*10**18, 5000*10**18, false, 0);
    
        pxs[0] = 1200;

        vm.prank(oracleOwner);
            oracle.setValues(block.number, pxs, pxs);

        require(perp.getPositionPnl(user, 0) == -1000*10**18, "pnl incorrect");
        
        
        require(perp.liquidatePosition(user, 0) == true, "did not liquidate");
    }

    function test_liquidateLong() public {
        uint256[] memory pxs = new uint256[](100);
        pxs[0] = 1000;
        vm.prank(oracleOwner);
            oracle.setValues(block.number, pxs, pxs);

        vm.prank(user);
            perp.openPosition(1000*10**18, 5000*10**18, true, 0);
    
        pxs[0] = 800;

        vm.prank(oracleOwner);
            oracle.setValues(block.number, pxs, pxs);

        require(perp.getPositionPnl(user, 0) == -1000*10**18, "pnl incorrect");
        
        
        require(perp.liquidatePosition(user, 0) == true, "did not liquidate");
    }

    function test_partialPosition() public {
        uint256[] memory pxs = new uint256[](100);
        pxs[0] = 1000;
        vm.prank(oracleOwner);
            oracle.setValues(block.number, pxs, pxs);

        vm.prank(user);
            perp.openPosition(1000*10**18, 5000*10**18, true, 0);
    
        pxs[0] = 900;

        vm.prank(oracleOwner);
            oracle.setValues(block.number, pxs, pxs);

        require(perp.getPositionPnl(user, 0) == -500*10**18, "pnl incorrect");
        
        vm.startPrank(user);
            perp.closePosition(2500*10**18, 0);
        vm.stopPrank();

        Perpetual.GetPosition[] memory positions = perp.getUserPositions(user);
        console.log('debt',positions[0].debt);
        require(positions[0].tokenNotional == 2500*10**18, "token notional incorrect");
        require(positions[0].debt == 2000*10**18, "debt incorrect");
        require(positions[0].margin == 500*10**18, "margin incorrect");
        
    }


    function test_partialPositionShort() public {
        uint256[] memory pxs = new uint256[](100);
        pxs[0] = 1000;
        vm.prank(oracleOwner);
            oracle.setValues(block.number, pxs, pxs);

        vm.prank(user);
            perp.openPosition(1000*10**18, 5000*10**18, false, 0);
    
        pxs[0] = 900;

        vm.prank(oracleOwner);
            oracle.setValues(block.number, pxs, pxs);

        require(perp.getPositionPnl(user, 0) == 500*10**18, "pnl incorrect");
        
        vm.startPrank(user);
            perp.closePosition(2500*10**18, 0);
        vm.stopPrank();

        Perpetual.GetPosition[] memory positions = perp.getUserPositions(user);
        console.log('debt',positions[0].debt);
        require(positions[0].tokenNotional == 2500*10**18, "token notional incorrect");
        require(positions[0].debt == 2000*10**18, "debt incorrect");
        require(positions[0].margin == 500*10**18, "margin incorrect");
        
    }


    function test_partialPositionShort2() public {
        uint256[] memory pxs = new uint256[](100);
        pxs[0] = 1000;
        vm.prank(oracleOwner);
            oracle.setValues(block.number, pxs, pxs);

        vm.prank(user);
            perp.openPosition(1000*10**18, 5000*10**18, false, 0);
    
        pxs[0] = 1100;

        vm.prank(oracleOwner);
            oracle.setValues(block.number, pxs, pxs);

        require(perp.getPositionPnl(user, 0) == -500*10**18, "pnl incorrect");
        
        vm.startPrank(user);
            perp.closePosition(2500*10**18, 0);
        vm.stopPrank();

        Perpetual.GetPosition[] memory positions = perp.getUserPositions(user);
        console.log('debt',positions[0].debt);
        require(positions[0].tokenNotional == 2500*10**18, "token notional incorrect");
        require(positions[0].debt == 2000*10**18, "debt incorrect");
        require(positions[0].margin == 500*10**18, "margin incorrect");
        
    }
}
