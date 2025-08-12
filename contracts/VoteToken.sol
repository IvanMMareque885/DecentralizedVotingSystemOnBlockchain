// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import standard ERC20 from OpenZeppelin
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VoteToken is ERC20 {
    constructor() ERC20("Vote Token", "VTK") {
        // Mint 1,000 tokens to the deployer
        _mint(msg.sender, 1000 * 10 ** decimals());
    }

    // Allow admin to mint more tokens later if needed
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
