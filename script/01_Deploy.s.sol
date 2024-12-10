// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";
import { Contract } from "src/Contract.sol";

/**
 * @title DeployScript
 * @dev This script is a deploy script template that creates a new Contract instance
 */
contract Deploy is Script {
    address _deployerAddress;

    function run() external returns (Contract Contract_) {
        _handleEnvVariables();

        vm.startBroadcast(_deployerAddress);

        Contract_ = new Contract();

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
