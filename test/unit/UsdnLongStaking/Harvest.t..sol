// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { Vm } from "forge-std/Vm.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";
import { FixedPointMathLib } from "solady/src/utils/FixedPointMathLib.sol";

import { USER_1 } from "../../utils/Constants.sol";
import { UsdnLongStakingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the {IUsdnLongStaking.harvest} of the USDN long staking
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

        usdnProtocol.setPosition(position, DEFAULT_TICK_VERSION, false);
        posHash = staking.hashPosId(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        staking.deposit(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX, "");
    }

    /**
     * @custom:scenario Tests the harvest with a deposited position.
     * @custom:given The staking contract with a deposited position.
     * @custom:when The function {IUsdnLongStaking.harvest} is called.
     * @custom:then The reward is sent to the position owner.
     * @custom:and A `UsdnLongStakingHarvest` event is emitted.
     */
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

    /**
     * @custom:scenario Tests the harvest with the position info updated.
     * @custom:given The staking contract with a deposited position.
     * @custom:when The function {IUsdnLongStaking.harvest} is called.
     * @custom:then The reward is sent to the position owner.
     * @custom:and The reward debt is updated.
     */
    function test_harvestPosInfoUpdated() public {
        uint256 rewardsPerBlock = farming.getRewardsPerBlock();
        uint256 blockNumberSkip = 100;

        vm.roll(block.number + blockNumberSkip);
        vm.prank(USER_1);
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

    /**
     * @custom:scenario Zero rewards is pending so no rewards are sent.
     * @custom:given The staking contract with a deposited position.
     * @custom:when The function {IUsdnLongStaking.harvest} is called with zero rewards.
     * @custom:then The reward is not sent to the position owner.
     * @custom:and No logs are emitted.
     */
    function test_harvestZeroRewards() public {
        vm.recordLogs();
        staking.harvest(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 0, "No logs must be emitted");
    }

    /**
     * @custom:scenario Reverts when the position is invalid.
     * @custom:given The staking contract with a deposited position.
     * @custom:when The function {IUsdnLongStaking.harvest} is called with an invalid position.
     * @custom:then The call should revert with {UsdnLongStakingInvalidPosition} error.
     */
    function test_RevertWhen_harvestInvalidPosition() public {
        vm.expectRevert(UsdnLongStakingInvalidPosition.selector);
        staking.harvest(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX + 1);
    }

    /**
     * @custom:scenario Tests the harvest with the position liquidated in the USDN protocol.
     * @custom:given The staking contract with a deposited position.
     * @custom:and The position is liquidated in the USDN protocol.
     * @custom:when The function {IUsdnLongStaking.harvest} is called.
     * @custom:then The reward is sent to the liquidator and the dead address.
     * @custom:and The position is deleted and the position's owner does not receive rewards.
     * @custom:and A `UsdnLongStakingLiquidate` event is emitted.
     */
    function test_harvestPositionLiquidate() public {
        uint256 blockNumberSkip = 100;
        vm.roll(block.number + blockNumberSkip);

        uint256 liquidatorReward = 151;
        uint256 burned = 354;

        usdnProtocol.setPosition(position, DEFAULT_TICK_VERSION, true);

        vm.prank(USER_1);
        vm.expectEmit();
        emit UsdnLongStakingLiquidate(USER_1, posHash, liquidatorReward, burned);
        staking.harvest(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        assertEq(rewardToken.balanceOf(address(this)), 0, "The reward sent to the liquidator and the dead address");
        assertEq(rewardToken.balanceOf(address(0xdead)), burned, "Dead address must receive a part of the rewards");
        assertEq(rewardToken.balanceOf(USER_1), liquidatorReward, "The liquidator must receive a part of the rewards");

        PositionInfo memory posInfo = staking.getPositionInfo(posHash);
        assertEq(posInfo.owner, address(0), "The reward debt must be updated");
    }

    /**
     * @custom:scenario Reverts when caller is not the owner
     * @custom:when Call the function {IUsdnLongStaking.setLiquidatorRewardBps} with a non-owner account
     * @custom:then It reverts with a OwnableUnauthorizedAccount error
     */
    function test_RevertWhen_setLiquidatorRewardBpsCallerIsNotTheOwner() public {
        vm.prank(USER_1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER_1));
        staking.setLiquidatorRewardBps(100);
    }
}
