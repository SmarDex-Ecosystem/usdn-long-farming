// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IUsdnLongStakingTypes } from "../../../../src/interfaces/IUsdnLongStakingTypes.sol";
import { IUsdnLongStakingErrors } from "../../../../src/interfaces/IUsdnLongStakingErrors.sol";
import { IUsdnLongStakingEvents } from "../../../../src/interfaces/IUsdnLongStakingEvents.sol";

import { BaseFixture } from "../../../utils/Fixtures.sol";
import { UsdnLongStakingHandler } from "./Handler.sol";
import { MockFarmingRange } from "./MockFarmingRange.sol";
import { MockRewardToken } from "./MockRewardToken.sol";

/**
 * @title UsdnLongStakingBaseFixture
 * @dev Utils for testing the USDN Long Staking
 */
contract UsdnLongStakingBaseFixture is
    BaseFixture,
    IUsdnLongStakingTypes,
    IUsdnLongStakingErrors,
    IUsdnLongStakingEvents
{
    MockRewardToken internal rewardToken;
    MockFarmingRange internal farming;
    UsdnLongStakingHandler internal staking;

    function _setUp() internal virtual {
        rewardToken = new MockRewardToken();
        farming = new MockFarmingRange(address(rewardToken));
        staking = new UsdnLongStakingHandler(farming);
    }
}
