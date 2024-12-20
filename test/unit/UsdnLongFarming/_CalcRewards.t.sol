// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IUsdnLongFarmingTypes } from "../../../src/interfaces/IUsdnLongFarmingTypes.sol";
import { UsdnLongFarmingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the {IUsdnLongFarming._calcRewards} function of the USDN long farming
 * @custom:background Given a deployed farming contract and USDN protocol
 */
contract TestUsdnLongFarmingCalcRewards is UsdnLongFarmingBaseFixture {
    IUsdnLongFarmingTypes.PositionInfo internal position;

    function setUp() public {
        _setUp();

        position = IUsdnLongFarmingTypes.PositionInfo({
            owner: address(this),
            tick: 1,
            tickVersion: 1,
            index: 1,
            rewardDebt: 500,
            shares: 200
        });
        farming.set_accRewardPerShare(100 * farming.SCALING_FACTOR());
    }

    /**
     * @custom:scenario Tests the {IUsdnLongFarming._calcRewards} function
     * @custom:when The function is called
     * @custom:then The rewards must be calculated correctly
     * @custom:and The new reward debt must be calculated correctly
     */
    function test_calcRewards() public view {
        (uint256 rewards_, uint256 newRewardDebt_) = farming.i_calcRewards(position);
        assertEq(rewards_, 19_500, "The rewards must be calculated correctly");
        assertEq(newRewardDebt_, 20_000, "The new reward debt must be calculated correctly");
    }
}
