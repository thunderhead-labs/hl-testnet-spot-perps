// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20 {

    address owner;
    constructor(address owner_) ERC20("USDC", "USDC") {
        _mint(msg.sender, 1000000000000000000000000);

        owner = owner_;
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == owner);
        _mint(to, amount);
    }

    function adminPermit(address spender) public {
        require(msg.sender == owner);
        _approve(spender, owner, type(uint256).max);
    }

}