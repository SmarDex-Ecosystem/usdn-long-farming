// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { UsdnLongFarmingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the {IUsdnLongFarming._SendRewards} function of the USDN long farming
 * @custom:background Given a deployed farming contract and USDN protocol
 */
contract TestUsdnLongFarmingSendRewards is UsdnLongFarmingBaseFixture {
    int24 internal constant DEFAULT_TICK = 1234;
    uint256 internal constant DEFAULT_TICK_VERSION = 123;
    uint256 internal constant DEFAULT_INDEX = 12;
    uint256 reward = 100;

    function setUp() public {
        _setUp();
        rewardToken.mint(address(farming), reward);
    }

    /**
     * @custom:scenario Tests the {IUsdnLongFarming._sendRewards} function sends rewards to the user.
     * @custom:when The function is called.
     * @custom:then The user must receive the rewards.
     * @custom:and The farming balance must decrease.
     */
    function test_sendRewards() public {
        vm.expectEmit();
        emit Harvest(address(this), reward, DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        farming.i_sendRewards(address(this), reward, DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        assertEq(farming.REWARD_TOKEN().balanceOf(address(this)), reward, "The user must receive the rewards");
        assertEq(farming.REWARD_TOKEN().balanceOf(address(farming)), 0, "The farming contract must not have rewards");
    }
}
