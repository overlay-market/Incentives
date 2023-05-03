// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor() ERC20("TestToken", "TT") {
        _mint(_msgSender(), 100000 * (10 ** uint256(decimals())));
    }

    function faucet(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
