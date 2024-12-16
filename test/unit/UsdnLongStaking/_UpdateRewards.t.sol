// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { UsdnLongStakingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the internal {_updateRewards} of the USDN long staking.
 * @custom:background Given a deployed staking contract and USDN protocol.
 */
contract TestUsdnLongStakingUpdateRewards is UsdnLongStakingBaseFixture {
    uint256 internal constant INITIAL_BLOCK = 123_456_789;

    function setUp() public {
        vm.roll(INITIAL_BLOCK);
        _setUp();
    }

    /**
     * @custom:scenario Tests the {_updateRewards} function without deposited shares.
     * @custom:when The function {i_updateRewards} is called.
     * @custom:then The {_accRewardPerShare} must be 0.
     * @custom:and The {_lastRewardBlock} must be updated.
     * @custom:and The contract balance of reward token must be 0.
     */
    function test_updateRewardsWithoutShares() public {
        staking.i_updateRewards();
        assertEq(staking.getAccRewardPerShare(), 0, "The reward per shares must not be updated");
        assertEq(staking.getLastRewardBlock(), INITIAL_BLOCK, "The last reward block must be updated");
        assertEq(rewardToken.balanceOf(address(staking)), 0, "The staking reward token balance must be 0");
    }

    /**
     * @custom:scenario Tests the {_updateRewards} function with deposited shares.
     * @custom:when The function {i_updateRewards} is called.
     * @custom:then The {_accRewardPerShare} must be updated.
     * @custom:and The {_lastRewardBlock} must be updated.
     * @custom:and The contract balance of reward token must be updated.
     */
    function test_updateRewardsWithShares() public {
        uint256 previousLastRewardBlock = staking.getLastRewardBlock();

        staking.setTotalShares(farming.getRewardsPerBlock() * INITIAL_BLOCK);
        staking.i_updateRewards();

        assertEq(
            staking.getAccRewardPerShare(),
            staking.SCALING_FACTOR(),
            "The reward per shares accumulator must be equal to the `SCALING_FACTOR`"
        );

        assertEq(staking.getLastRewardBlock(), INITIAL_BLOCK, "The last reward block must be updated");

        assertEq(
            rewardToken.balanceOf(address(staking)),
            (INITIAL_BLOCK - previousLastRewardBlock) * farming.getRewardsPerBlock(),
            "The staking reward token balance must be different"
        );
    }
}
