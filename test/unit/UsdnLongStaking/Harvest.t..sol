// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";
import { FixedPointMathLib } from "solady/src/utils/FixedPointMathLib.sol";

import { UsdnLongStakingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the {harvest} of the USDN long staking
 * @custom:background Given a deployed staking contract and USDN protocol
 */
contract TestUsdnLongStakingHarvest is UsdnLongStakingBaseFixture {
    IUsdnProtocolTypes.Position internal position;
    bytes32 posHash;
    int24 internal constant DEFAULT_TICK = 1234;
    uint256 internal constant DEFAULT_TICK_VERSION = 123;
    uint256 internal constant DEFAULT_INDEX = 12;

    function setUp() public {
        _setUp();

        position = IUsdnProtocolTypes.Position({
            validated: true,
            timestamp: uint40(block.timestamp),
            user: address(this),
            totalExpo: 20,
            amount: 10
        });

        usdnProtocol.setPosition(position);
        posHash = staking.getPosIdHash(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        bool success = staking.deposit(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX, "");
        assertTrue(success, "The deposit must be successful");
    }

    function test_harvest() public {
        uint256 rewardsPerBlock = farming.getRewardsPerBlock();
        uint256 blockNumberSkip = 100;
        uint256 expectedRewards = rewardsPerBlock * (blockNumberSkip + 1);
        vm.roll(block.number + blockNumberSkip);
        vm.expectEmit();
        emit UsdnLongStakingHarvest(address(this), posHash, expectedRewards);
        staking.harvest(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        assertEq(rewardToken.balanceOf(address(this)), expectedRewards, "The reward token balance must be updated");
    }

    function test_harvestPosInfoUpdated() public {
        uint256 rewardsPerBlock = farming.getRewardsPerBlock();
        uint256 blockNumberSkip = 100;

        vm.roll(block.number + blockNumberSkip);
        staking.harvest(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        assertEq(
            rewardToken.balanceOf(address(this)),
            rewardsPerBlock * (blockNumberSkip + 1),
            "The reward token balance must be updated"
        );
        PositionInfo memory posInfo = staking.getPositionInfo(posHash);
        assertEq(
            posInfo.rewardDebt,
            FixedPointMathLib.fullMulDiv(posInfo.shares, staking.getAccRewardPerShare(), staking.SCALING_FACTOR()),
            "The reward debt must be updated"
        );
    }
}
