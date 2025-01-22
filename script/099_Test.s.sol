// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Script, console2 } from "forge-std/Script.sol";

contract TestScript is Script {
    function run() external {
        console2.log("me", msg.sender);
    }
}
