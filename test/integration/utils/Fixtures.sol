// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { IERC20 } from "@openzeppelin-contracts-5/token/ERC20/IERC20.sol";
import { IUsdnProtocol } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocol.sol";
import { UsdnProtocolBaseIntegrationFixture } from "@smardex-usdn-test/integration/UsdnProtocol/utils/Fixtures.sol";
import { LibRLP } from "solady-0.0.281//utils/LibRLP.sol";

import { FarmingToken } from "../../../../src/FarmingToken.sol";
import { IUsdnLongFarmingErrors } from "../../../../src/interfaces/IUsdnLongFarmingErrors.sol";
import { IUsdnLongFarmingEvents } from "../../../../src/interfaces/IUsdnLongFarmingEvents.sol";
import { IUsdnLongFarmingTypes } from "../../../../src/interfaces/IUsdnLongFarmingTypes.sol";
import { IFarmingRange } from "src/interfaces/IFarmingRange.sol";

import { DEPLOYER, SDEX } from "../../utils/Constants.sol";
import { UsdnLongFarmingHandler } from "./Handler.sol";

/**
 * @title UsdnLongFarmingIntegrationFixture
 * @dev Utils for testing the USDN Long Farming
 */
contract UsdnLongFarmingIntegrationFixture is
    UsdnProtocolBaseIntegrationFixture,
    IUsdnLongFarmingTypes,
    IUsdnLongFarmingErrors,
    IUsdnLongFarmingEvents
{
    IERC20 internal rewardToken = IERC20(SDEX);
    FarmingToken internal farmingToken;
    IFarmingRange internal rewardsProvider = IFarmingRange(0x7d85C0905a6E1Ab5837a0b57cD94A419d3a77523);
    UsdnLongFarmingHandler internal farming;

    uint256 internal constant TOTAL_REWARDS = 100_000_000 ether;
    uint256 internal constant REWARDS_PER_BLOCK = 100;

    uint256 internal campaignId;
    uint256 internal startBlock;
    address internal farmingAddress;
    address internal farmingRangeOwner;
    address internal rewardManager;

    function _setUp() internal virtual {
        string memory url = vm.rpcUrl("mainnet");
        vm.createSelectFork(url);
        vm.rollFork(20_014_134);

        // deploy usdn protocol
        params = DEFAULT_PARAMS;
        params.initialDeposit = 502 ether;
        params.initialLong = 500 ether;
        _setUp(params);

        // deploy farming token
        vm.prank(DEPLOYER);
        farmingToken = new FarmingToken();

        // store values
        farmingAddress = LibRLP.computeAddress(DEPLOYER, vm.getNonce(DEPLOYER));
        farmingRangeOwner = rewardsProvider.owner();
        rewardManager = rewardsProvider.rewardManager();
        campaignId = rewardsProvider.campaignInfoLen();
        startBlock = block.number + 10;

        // set smardex farming rewards
        deal(address(rewardToken), rewardManager, TOTAL_REWARDS);
        vm.startPrank(farmingRangeOwner);
        rewardsProvider.addCampaignInfo(farmingToken, rewardToken, startBlock);
        rewardsProvider.addRewardInfo(campaignId, startBlock + TOTAL_REWARDS / REWARDS_PER_BLOCK, REWARDS_PER_BLOCK);
        vm.stopPrank();

        // deploy usdn long farming
        vm.startPrank(DEPLOYER);
        farmingToken.approve(farmingAddress, 1);
        farming = new UsdnLongFarmingHandler(IUsdnProtocol(address(protocol)), rewardsProvider, campaignId);
        vm.stopPrank();
    }
}
