// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IERC20 } from "@openzeppelin-contracts-5/token/ERC20/IERC20.sol";

import { Script } from "forge-std/Script.sol";

import { IFarmingRange } from "src/interfaces/IFarmingRange.sol";

contract AddCampaign is Script {
    IFarmingRange constant FARMING_RANGE = IFarmingRange(0x7d85C0905a6E1Ab5837a0b57cD94A419d3a77523);
    IERC20 constant SDEX = IERC20(0x5DE8ab7E27f6E7A1fFf3E5B337584Aa43961BEeF);

    IERC20 internal _farmingToken;

    function run() external {
        _handleEnvVariables();

        address owner = FARMING_RANGE.owner();

        vm.broadcast(owner);
        FARMING_RANGE.addCampaignInfo(_farmingToken, SDEX, block.number + 10);
    }

    /// @notice Handle the environment variables
    function _handleEnvVariables() internal {
        try vm.envAddress("FARMING_TOKEN_ADDRESS") {
            _farmingToken = IERC20(vm.envAddress("FARMING_TOKEN_ADDRESS"));
        } catch {
            _farmingToken = IERC20(vm.parseAddress(vm.prompt("enter FARMING_TOKEN_ADDRESS")));
        }

        string memory etherscanApiKey = vm.envOr("ETHERSCAN_API_KEY", string("XXXXXXXXXXXXXXXXX"));
        vm.setEnv("ETHERSCAN_API_KEY", etherscanApiKey);
    }
}
