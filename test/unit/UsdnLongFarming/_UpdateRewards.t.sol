// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { UsdnLongFarmingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the internal {UsdnLongFarming._updateRewards} function of the USDN long farming.
 * @custom:background Given a deployed farming contract and USDN protocol.
 */
contract TestUsdnLongFarmingUpdateRewards is UsdnLongFarmingBaseFixture {
    uint256 internal constant INITIAL_BLOCK = 123_456_789;

    function setUp() public {
        vm.roll(INITIAL_BLOCK);
        _setUp();
    }

    /**
     * @custom:scenario Tests the {UsdnLongFarming._updateRewards} function without deposited shares.
     * @custom:when The function is called.
     * @custom:then The {UsdnLongFarming._accRewardPerShare} must be 0.
     * @custom:and The {UsdnLongFarming._lastRewardBlock} must be updated.
     * @custom:and The contract balance of rewards token must be 0.
     */
    function test_updateRewardsWithoutShares() public {
        farming.i_updateRewards();
        assertEq(farming.getAccRewardPerShare(), 0, "The reward per shares must not be updated");
        assertEq(farming.getLastRewardBlock(), INITIAL_BLOCK, "The last reward block must be updated");
        assertEq(rewardToken.balanceOf(address(farming)), 0, "The farming reward token balance must be 0");
    }

    /**
     * @custom:scenario Tests the {UsdnLongFarming._updateRewards} function with deposited shares.
     * @custom:when The function is called.
     * @custom:then The {UsdnLongFarming._accRewardPerShare} must be updated.
     * @custom:and The {UsdnLongFarming._lastRewardBlock} must be updated.
     * @custom:and The contract balance of rewards token must be updated.
     */
    function test_updateRewardsWithShares() public {
        uint256 previousLastRewardBlock = farming.getLastRewardBlock();

        farming.setTotalShares(rewardsProvider.getRewardsPerBlock() * INITIAL_BLOCK);
        farming.i_updateRewards();

        assertEq(
            farming.getAccRewardPerShare(),
            farming.SCALING_FACTOR(),
            "The reward per shares accumulator must be equal to the `SCALING_FACTOR`"
        );

        assertEq(farming.getLastRewardBlock(), INITIAL_BLOCK, "The last reward block must be updated");

        assertEq(
            rewardToken.balanceOf(address(farming)),
            (INITIAL_BLOCK - previousLastRewardBlock) * rewardsProvider.getRewardsPerBlock(),
            "The farming reward token balance must be different"
        );
    }
}
