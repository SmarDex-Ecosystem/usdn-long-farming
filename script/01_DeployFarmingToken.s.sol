// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";

import { FarmingToken } from "src/FarmingToken.sol";

contract DeployFarmingToken is Script {
    address internal _deployerAddress;

    function run() external returns (FarmingToken farmingToken_) {
        _handleEnvVariables();

        vm.broadcast(_deployerAddress);
        farmingToken_ = new FarmingToken();
    }

    /// @notice Handle the environment variables
    function _handleEnvVariables() internal {
        try vm.envAddress("DEPLOYER_ADDRESS") returns (address deployerAddress_) {
            _deployerAddress = deployerAddress_;
        } catch {
            _deployerAddress = vm.parseAddress(vm.prompt("enter DEPLOYER_ADDRESS"));
        }

        string memory etherscanApiKey = vm.envOr("ETHERSCAN_API_KEY", string("XXXXXXXXXXXXXXXXX"));
        vm.setEnv("ETHERSCAN_API_KEY", etherscanApiKey);
    }
}
