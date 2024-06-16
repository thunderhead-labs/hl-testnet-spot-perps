// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./SystemOracle.sol";
import "./USDC.sol";

import "forge-std/console.sol";
contract Perpetual {


    SystemOracle public oracle = SystemOracle(0x1111111111111111111111111111111111111111);
    USDC public usdc;
    address owner;

    struct Position {
        uint tokenNotional;
        uint margin;
        uint debt;
        bool isLong;
        bool active;
    }

    struct GetPosition {
        uint tokenNotional;
        uint margin;
        uint debt;
        bool isLong;
        bool active;

        int256 pnl;
        uint256 positionValue;
        uint256 assetIndex;
    }

    struct User {
        int256 totalPnl;
        uint256 totalVolume;
        bool claimedFaucet;
    }


    event Liquidated(address indexed user, uint256 indexed assetIndex, uint256 indexed amount);
    event PositionOpened(address indexed user, uint256 indexed assetIndex, uint256 indexed amount, uint256 margin, bool isLong);
    event PositionClosed(address indexed user, uint256 indexed assetIndex, int256 indexed pnl, uint256 amount);

    mapping (address => mapping (uint => Position)) public positions;
    mapping (address => User) public users;

    address[] public userList;

    constructor () {
        owner = msg.sender;
        usdc = new USDC(address(this));

        usdc.mint(address(this), 1_000_000_000_000*10**18);
    }

    function faucet() public {
        require(users[msg.sender].claimedFaucet == false, "already claimed faucet");

        usdc.transfer(msg.sender, 10000*10**18);

        userList.push(msg.sender);
    }

    function openPosition(uint256 margin, uint256 usdNotional, bool isLong, uint256 assetIndex) public returns (uint256){
        require(usdNotional / margin <= 1000, "leverage too high");

        usdc.adminPermit(msg.sender);
        usdc.transferFrom(msg.sender, address(this), margin);

        uint256[] memory pxs = oracle.getSpotOraclePxs();

        uint256 price = pxs[assetIndex];

        Position storage position = positions[msg.sender][assetIndex];

        require(position.active == false, "position already open");

        uint256 tokenNotional = usdNotional * 10**3 / price;

        position.margin += margin;
        position.tokenNotional += tokenNotional;
        position.debt += usdNotional - margin;
        position.isLong = isLong;
        position.active = true;


        emit PositionOpened(msg.sender, assetIndex, tokenNotional, margin, isLong);
        return tokenNotional;

    }

    function liquidatePosition(address user, uint256 assetIndex) public returns (bool) {
        
        uint256 margin = positions[user][assetIndex].margin;
        if (int(getPositionPnl(user, assetIndex)) + int(margin) <= 0) {

            emit Liquidated(user, assetIndex, getPositionValue(user, assetIndex));
            
            delete positions[user][assetIndex];

            users[user].totalPnl -= int(margin);

            return true;
        }

        return false;
    }

    function closePosition(uint256 tokenNotionalToClose, uint256 assetIndex) public returns (uint256) {
        Position storage position = positions[msg.sender][assetIndex];

        require(position.active, "position not open");
        require(tokenNotionalToClose <= position.tokenNotional, "tokenNotional too high");

        if (liquidatePosition(msg.sender, assetIndex)) {
            return 0;
        }

        int256 pnl = getPositionPnl(msg.sender, assetIndex);
        int256 partialPnl = pnl * int256(tokenNotionalToClose) / int256(position.tokenNotional);
        users[msg.sender].totalPnl += partialPnl;


        uint256 margin = position.margin;
        uint256 partialMargin = margin * tokenNotionalToClose / position.tokenNotional;
        uint256 debt = position.debt;
        uint256 partialDebt = debt * tokenNotionalToClose / position.tokenNotional;
        uint256 amountToTransfer = uint(int(partialMargin)  + partialPnl);


        users[msg.sender].totalVolume += amountToTransfer;

        usdc.transfer(msg.sender, amountToTransfer);

        emit PositionClosed(msg.sender, assetIndex, pnl, amountToTransfer);


        if (tokenNotionalToClose == position.tokenNotional) {
            delete positions[msg.sender][assetIndex];
        } else {
            console.log(position.margin, partialMargin);
            position.margin -= partialMargin;

            position.tokenNotional -= tokenNotionalToClose;

            console.log('initial debt', position.debt);
            position.debt -= partialDebt;
        }
    } 

    function balanceOfNotional(address user, uint256 assetIndex) public view returns (uint256) {
        return positions[user][assetIndex].tokenNotional;
    }

    function getPositionValue(address user, uint256 assetIndex) public view returns (uint256) {
        uint256[] memory pxs = oracle.getSpotOraclePxs();
        uint256 price = pxs[assetIndex];
        uint256 size = positions[user][assetIndex].tokenNotional;

        return size * price / 10**3;
    }

    function getPositionPnl(address user, uint256 assetIndex) public view returns (int256) {

        uint256 margin = positions[user][assetIndex].margin;
        uint256 debt = positions[user][assetIndex].debt;
        bool isLong = positions[user][assetIndex].isLong;

        uint256 positionValue = getPositionValue(user, assetIndex);

        if (isLong) {
            return int(positionValue) - int(debt) - int(margin);
        } else {
            return int(margin + debt) - int(positionValue);
        }
    }

    function getUserPositions(address user) public view returns (GetPosition[] memory) {
        uint256[] memory pxs  = oracle.getSpotOraclePxs();
        uint256 positionCount;
        for (uint i = 0; i < pxs.length; i++) {
            if (positions[user][i].active) {
                positionCount++;
            }
        }
        GetPosition[] memory userPositions = new GetPosition[](positionCount);

        uint j;
        for (uint i = 0; i < pxs.length; i++) {
            if (positions[user][i].active) {
                userPositions[j].tokenNotional = positions[user][i].tokenNotional;
                userPositions[j].margin = positions[user][i].margin;
                userPositions[j].debt = positions[user][i].debt;
                userPositions[j].isLong = positions[user][i].isLong;
                userPositions[j].active = positions[user][i].active;
                userPositions[j].pnl = getPositionPnl(user, i);
                userPositions[j].positionValue = getPositionValue(user, i);
                userPositions[j].assetIndex = i;
                j++;
            }
        }

        return userPositions;
    }

    function getAllUsersPnlList() public view returns (address[] memory, int256[] memory) {
        int256[] memory pnlList = new int256[](userList.length);

        for (uint i = 0; i < userList.length; i++) {
            pnlList[i] = users[userList[i]].totalPnl;
        }

        return (userList, pnlList);
    }

    function liquidateAllUsers() public {
        uint256 length = oracle.getSpotOraclePxs().length;

        for (uint i = 0; i < userList.length; i++) {
            for (uint j = 0; j < length; j++) {

                if (positions[userList[i]][j].active) {
                    liquidatePosition(userList[i], j);
                }
            }
        }
    }

    function getMarkOraclePxs() public returns (uint[] memory) {
        return oracle.getMarkOraclePxs();
    }
}
