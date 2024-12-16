// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { ERC20 } from "@openzeppelin-contracts-5/token/ERC20/ERC20.sol";

contract MockRewardToken is ERC20 {
    constructor() ERC20("Mock", "MOCK") { }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
