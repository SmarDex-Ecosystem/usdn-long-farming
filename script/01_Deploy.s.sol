// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { LibRLP } from "solady-0.0/utils/LibRLP.sol";

import { Script } from "forge-std/Script.sol";

contract DeployUsdnLongStaking is Script {
    address _deployerAddress;

    function run() external {
        _handleEnvVariables();

        vm.startBroadcast(_deployerAddress);

        // TODO:
        // - deploy farming token (mints 1 wei to deployer)
        // - create farming campaign with the farming token as staking token
        // - pre-compute address of the long staking contract (with LibRLP.computeAddress and vm.getNonce)
        // - approve the long staking contract to spend the farming token (1 wei)
        // - deploy the long staking contract by passing the farming contract address and campaign id

        // TODO: add return values for all deployed contracts

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
