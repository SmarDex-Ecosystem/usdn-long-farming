// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { LibRLP } from "solady-0.0/utils/LibRLP.sol";

import { DEPLOYER } from "../../../utils/Constants.sol";
import { BaseFixture } from "../../../utils/Fixtures.sol";
import { UsdnLongStakingHandler } from "./Handler.sol";
import { MockFarmingRange } from "./MockFarmingRange.sol";
import { MockRewardToken } from "./MockRewardToken.sol";

import { FarmingToken } from "../../../../src/FarmingToken.sol";
import { IUsdnLongStakingErrors } from "../../../../src/interfaces/IUsdnLongStakingErrors.sol";
import { IUsdnLongStakingEvents } from "../../../../src/interfaces/IUsdnLongStakingEvents.sol";
import { IUsdnLongStakingTypes } from "../../../../src/interfaces/IUsdnLongStakingTypes.sol";

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
    uint64 constant DEPLOYMENT_NONCE = 999; // deterministic nonce to be able to calculate the staking address

    MockRewardToken internal rewardToken;
    FarmingToken internal farmingToken;
    MockFarmingRange internal farming;
    UsdnLongStakingHandler internal staking;

    function _setUp() internal virtual {
        vm.startPrank(DEPLOYER);
        rewardToken = new MockRewardToken();
        farmingToken = new FarmingToken();
        farming = new MockFarmingRange(rewardToken, farmingToken);
        // approve future staking contract
        address stakingAddress = LibRLP.computeAddress(DEPLOYER, DEPLOYMENT_NONCE);
        farmingToken.approve(stakingAddress, 1);
        // make sure the nonce is the same as we used to pre-compute the address
        vm.setNonce(DEPLOYER, DEPLOYMENT_NONCE);
        staking = new UsdnLongStakingHandler(farming);
        vm.stopPrank();
    }
}
