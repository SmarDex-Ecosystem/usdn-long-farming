// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { LibRLP } from "solady-0.0.281//utils/LibRLP.sol";

import { DEPLOYER } from "../../../utils/Constants.sol";
import { BaseFixture } from "../../../utils/Fixtures.sol";
import { UsdnLongFarmingHandler } from "./Handler.sol";

import { MockRewardToken } from "./MockRewardToken.sol";
import { MockRewardsProvider } from "./MockRewardsProvider.sol";
import { MockUsdnProtocol } from "./MockUsdnProtocol.sol";

import { FarmingToken } from "../../../../src/FarmingToken.sol";
import { IUsdnLongFarmingErrors } from "../../../../src/interfaces/IUsdnLongFarmingErrors.sol";
import { IUsdnLongFarmingEvents } from "../../../../src/interfaces/IUsdnLongFarmingEvents.sol";
import { IUsdnLongFarmingTypes } from "../../../../src/interfaces/IUsdnLongFarmingTypes.sol";

/**
 * @title UsdnLongFarmingBaseFixture
 * @dev Utils for testing the USDN Long Farming
 */
contract UsdnLongFarmingBaseFixture is
    BaseFixture,
    IUsdnLongFarmingTypes,
    IUsdnLongFarmingErrors,
    IUsdnLongFarmingEvents
{
    uint64 constant DEPLOYMENT_NONCE = 999; // deterministic nonce to be able to calculate the farming address

    MockRewardToken internal rewardToken;
    FarmingToken internal farmingToken;
    MockRewardsProvider internal rewardsProvider;
    MockUsdnProtocol internal usdnProtocol;
    UsdnLongFarmingHandler internal farming;

    function _setUp() internal virtual {
        vm.startPrank(DEPLOYER);
        rewardToken = new MockRewardToken();
        farmingToken = new FarmingToken();
        rewardsProvider = new MockRewardsProvider(rewardToken, farmingToken);
        usdnProtocol = new MockUsdnProtocol();
        // approve future farming contract
        address farmingAddress = LibRLP.computeAddress(DEPLOYER, DEPLOYMENT_NONCE);
        farmingToken.approve(farmingAddress, 1);
        // make sure the nonce is the same as we used to pre-compute the address
        vm.setNonce(DEPLOYER, DEPLOYMENT_NONCE);
        farming = new UsdnLongFarmingHandler(usdnProtocol, rewardsProvider);
        vm.stopPrank();
    }
}
