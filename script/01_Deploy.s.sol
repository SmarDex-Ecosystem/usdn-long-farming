// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { UsdnLongStaking } from "../src/UsdnLongStaking.sol";
import { Script } from "forge-std/Script.sol";

contract DeployUsdnLongStaking is Script {
    address _deployerAddress;

    function run() external returns (UsdnLongStaking Staking_) {
        _handleEnvVariables();

        vm.startBroadcast(_deployerAddress);

        // TODO: create contract

        vm.stopBroadcast();
    }

    /// @notice Handle the environment variables
    function _handleEnvVariables() internal {
        try vm.envAddress("DEPLOYER_ADDRESS") {
            _deployerAddress = vm.envAddress("DEPLOYER_ADDRESS");
        } catch {
            revert("DEPLOYER_ADDRESS is required");
        }

        string memory etherscanApiKey = vm.envOr("ETHERSCAN_API_KEY", string("XXXXXXXXXXXXXXXXX"));
        vm.setEnv("ETHERSCAN_API_KEY", etherscanApiKey);
    }
}
