// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenUsdt is ERC20 {
    constructor() ERC20("Token Usdt", "USDT") {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }
}