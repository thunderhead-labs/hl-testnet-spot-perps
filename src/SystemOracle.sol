// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SystemOracle {
  uint public sysBlockNumber;
  uint[] public markOraclePxs;
  uint[] public spotOraclePxs;

  modifier onlyOperator() {
    require(msg.sender == 0x2222222222222222222222222222222222222222, "Only operator allowed");
    _;
  }

  // Function to set the list of numbers, only the owner can call this
  function setValues(
    uint _sysBlockNumber,
    uint[] memory _markOraclePxs,
    uint[] memory _spotOraclePxs
  ) public onlyOperator {
    sysBlockNumber = _sysBlockNumber;
    markOraclePxs = _markOraclePxs;
    spotOraclePxs = _spotOraclePxs;
  }

  function getMarkOraclePxs() public view returns (uint[] memory) {
    return markOraclePxs;
  }

  function getSpotOraclePxs() public view returns (uint[] memory) {
    return spotOraclePxs;
  }
}