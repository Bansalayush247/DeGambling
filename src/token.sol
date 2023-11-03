// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("Token", "DGT") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}
