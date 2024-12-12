// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { ERC20 } from "solady-0.0/tokens/ERC20.sol";

contract MockRewardToken is ERC20 {
    function name() public pure override returns (string memory name_) {
        return "Mock";
    }

    function symbol() public pure override returns (string memory symbol_) {
        return "MOCK";
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
