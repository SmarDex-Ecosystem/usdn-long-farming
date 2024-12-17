// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { ERC20 } from "@openzeppelin-contracts-5/token/ERC20/ERC20.sol";

/**
 * @title Farming Token
 * @notice This token is used to receive reward tokens from the SmarDex farmingRange contract.
 */
contract FarmingToken is ERC20 {
    constructor() ERC20("USDN Long Farming", "ULFARM") {
        _mint(msg.sender, 1);
    }
}
