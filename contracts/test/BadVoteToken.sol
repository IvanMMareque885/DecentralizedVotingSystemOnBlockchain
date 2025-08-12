// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// A minimal broken ERC-20 implementation (for testing misuse)
contract BadVoteToken {
    string public name = "Broken VTK";
    string public symbol = "BVTK";
    uint8 public decimals = 0; // ❌ Incorrect decimals
    uint256 public totalSupply = 1_000_000;

    mapping(address => uint256) public balanceOf;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    // ❌ No approve or allowance logic
    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    // ❌ No transferFrom at all — breaks ERC-20 compliance
}
