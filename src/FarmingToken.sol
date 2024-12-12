// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { ERC20 } from "solady-0.0/tokens/ERC20.sol";

/**
 * @title Farming Token
 * @notice This token is used to receive reward tokens from the SmarDex `FarmingRange` contract.
 */
contract FarmingToken is ERC20 {
    error FarmingTokenUnauthorized();
    error FarmingTokenInitialized();

    constructor() {
        _mint(msg.sender, 1);
    }

    function name() public pure override returns (string memory name_) {
        return "USDN Long Farming";
    }

    function symbol() public pure override returns (string memory symbol_) {
        return "UFARM";
    }
}
