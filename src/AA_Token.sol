// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AA_Token is ERC20, Ownable {
    constructor() ERC20("Winnings", "WIN") Ownable(msg.sender) {}

    function mint(address to) external onlyOwner {
        require(to != address(0), "Cannot mint to zero address");
        _mint(to, 100 * 10 ** decimals()); // Mint 100 token with proper decimals
    }

    function getBalance(address account) external view returns (uint256) {
        return super.balanceOf(account);
    }
}
