// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { IERC20 } from "@openzeppelin-contracts-5/token/ERC20/IERC20.sol";
import { IUsdnProtocol } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocol.sol";
import { LibRLP } from "solady-0.0.281/utils/LibRLP.sol";

import { Script, console2 } from "forge-std/Script.sol";

import { UsdnLongFarming } from "src/UsdnLongFarming.sol";
import { IFarmingRange } from "src/interfaces/IFarmingRange.sol";

contract DeployUsdnLongFarming is Script {
    IFarmingRange constant FARMING_RANGE = IFarmingRange(0x7d85C0905a6E1Ab5837a0b57cD94A419d3a77523);
    IUsdnProtocol internal USDN_PROTOCOL = IUsdnProtocol(0x656cB8C6d154Aad29d8771384089be5B5141f01a);
    IERC20 internal FARMING_TOKEN = IERC20(0xCE1bc72A070349cb444743Ec3b2b4d8BF398DAf5);

    function run() external returns (UsdnLongFarming longFarming_) {
        _handleEnvVariables();

        console2.log(msg.sender);
        uint256 campaignID = FARMING_RANGE.campaignInfoLen() - 1;
        while (campaignID >= 0) {
            IFarmingRange.CampaignInfo memory campaignInfo = FARMING_RANGE.campaignInfo(campaignID);
            if (campaignInfo.stakingToken == FARMING_TOKEN) {
                break;
            }
            campaignID--;
        }

        require(campaignID > 0, "DeployUsdnLongFarming: campaign not found");

        address longFarmingAddress = LibRLP.computeAddress(msg.sender, vm.getNonce(msg.sender) + 1);

        vm.startBroadcast(msg.sender);
        FARMING_TOKEN.approve(longFarmingAddress, 1);
        longFarming_ = new UsdnLongFarming(USDN_PROTOCOL, FARMING_RANGE, campaignID);
        vm.stopBroadcast();
    }

    /// @notice Handle the environment variables
    function _handleEnvVariables() internal {
        string memory etherscanApiKey = vm.envOr("ETHERSCAN_API_KEY", string("XXXXXXXXXXXXXXXXX"));
        vm.setEnv("ETHERSCAN_API_KEY", etherscanApiKey);
    }
}
