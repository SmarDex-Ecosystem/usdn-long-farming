// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IERC20 } from "@openzeppelin-contracts-5/token/ERC20/IERC20.sol";
import { IUsdnProtocol } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocol.sol";
import { LibRLP } from "solady-0.0/utils/LibRLP.sol";

import { Script } from "forge-std/Script.sol";

import { FarmingToken } from "src/FarmingToken.sol";
import { UsdnLongFarming } from "src/UsdnLongFarming.sol";
import { IFarmingRange } from "src/interfaces/IFarmingRange.sol";

contract DeployUsdnLongFarming is Script {
    IFarmingRange constant FARMING_RANGE = IFarmingRange(0x7d85C0905a6E1Ab5837a0b57cD94A419d3a77523);
    IERC20 constant SDEX = IERC20(0x5DE8ab7E27f6E7A1fFf3E5B337584Aa43961BEeF);

    IUsdnProtocol internal _usdnProtocol;
    address internal _deployerAddress;

    function run() external returns (FarmingToken farmingToken_, UsdnLongFarming longFarming_) {
        _handleEnvVariables();

        vm.broadcast(_deployerAddress);
        farmingToken_ = new FarmingToken();

        address owner = FARMING_RANGE.owner();
        vm.broadcast(owner);
        FARMING_RANGE.addCampaignInfo(farmingToken_, SDEX, block.number + 1);

        uint256 campaignID = FARMING_RANGE.campaignInfoLen() - 1;
        address longFarmingAddress = LibRLP.computeAddress(_deployerAddress, vm.getNonce(_deployerAddress) + 1);

        vm.startBroadcast(_deployerAddress);
        farmingToken_.approve(longFarmingAddress, 1);
        longFarming_ = new UsdnLongFarming(_usdnProtocol, FARMING_RANGE, campaignID);
        vm.stopBroadcast();
    }

    /// @notice Handle the environment variables
    function _handleEnvVariables() internal {
        try vm.envAddress("DEPLOYER_ADDRESS") {
            _deployerAddress = vm.envAddress("DEPLOYER_ADDRESS");
        } catch {
            _deployerAddress = vm.parseAddress(vm.prompt("enter DEPLOYER_ADDRESS"));
        }

        try vm.envAddress("USDN_PROTOCOL_ADDRESS") {
            _usdnProtocol = IUsdnProtocol(vm.envAddress("USDN_PROTOCOL_ADDRESS"));
        } catch {
            _usdnProtocol = IUsdnProtocol(vm.parseAddress(vm.prompt("enter USDN_PROTOCOL_ADDRESS")));
        }

        string memory etherscanApiKey = vm.envOr("ETHERSCAN_API_KEY", string("XXXXXXXXXXXXXXXXX"));
        vm.setEnv("ETHERSCAN_API_KEY", etherscanApiKey);
    }
}
