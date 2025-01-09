// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { IERC20 } from "@openzeppelin-contracts-5/token/ERC20/IERC20.sol";

import { IUsdnProtocol } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocol.sol";
import { UsdnProtocolBaseIntegrationFixture } from "@smardex-usdn-test/integration/UsdnProtocol/utils/Fixtures.sol";
import { LibRLP } from "solady-0.0.281//utils/LibRLP.sol";

import { FarmingToken } from "../../../src/FarmingToken.sol";
import { UsdnLongFarming } from "../../../src/UsdnLongFarming.sol";
import { IFarmingRange } from "../../../src/interfaces/IFarmingRange.sol";
import { IUsdnLongFarmingErrors } from "../../../src/interfaces/IUsdnLongFarmingErrors.sol";
import { IUsdnLongFarmingEvents } from "../../../src/interfaces/IUsdnLongFarmingEvents.sol";
import { IUsdnLongFarmingTypes } from "../../../src/interfaces/IUsdnLongFarmingTypes.sol";
import { DEPLOYER, SDEX } from "../../utils/Constants.sol";

/**
 * @title UsdnLongFarmingBaseIntegrationFixture
 * @dev Utils for testing the USDN Long Farming
 */
contract UsdnLongFarmingBaseIntegrationFixture is
    UsdnProtocolBaseIntegrationFixture,
    IUsdnLongFarmingTypes,
    IUsdnLongFarmingErrors,
    IUsdnLongFarmingEvents
{
    FarmingToken internal farmingToken;
    IFarmingRange internal rewardsProvider = IFarmingRange(address(0x7d85C0905a6E1Ab5837a0b57cD94A419d3a77523));
    address internal rewardsProviderOwner;
    uint256 internal rewardStartingBlock;
    uint256 internal rewardEndingBlock;
    uint256 internal campaignID;
    uint256 internal REWARD_PER_BLOCKS = 1;
    UsdnLongFarming internal farming;

    function _setUp() internal virtual {
        string memory url = vm.rpcUrl("mainnet");
        vm.createSelectFork(url);
        vm.rollFork(20_014_134);
        SetUpParams memory params = DEFAULT_PARAMS;
        params.enableRoles = false;
        params.initialLong = 1000 ether;
        _setUp(params);

        vm.prank(DEPLOYER);
        farmingToken = new FarmingToken();

        rewardStartingBlock = block.number + 10;
        rewardEndingBlock = block.number + 1000;
        rewardsProviderOwner = rewardsProvider.owner();
        campaignID = rewardsProvider.campaignInfoLen();

        vm.startPrank(rewardsProviderOwner);
        rewardsProvider.addCampaignInfo(farmingToken, IERC20(SDEX), rewardStartingBlock);
        rewardsProvider.addRewardInfo(campaignID, rewardEndingBlock, REWARD_PER_BLOCKS);
        vm.stopPrank();

        // approve future farming contract
        address farmingAddress = LibRLP.computeAddress(DEPLOYER, vm.getNonce(DEPLOYER));
        vm.startPrank(DEPLOYER);
        farmingToken.approve(farmingAddress, 1);
        farming = new UsdnLongFarming(IUsdnProtocol(address(protocol)), rewardsProvider, campaignID);
        vm.stopPrank();
    }
}
