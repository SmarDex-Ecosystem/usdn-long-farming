// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { Vm } from "forge-std/Vm.sol";

import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";
import { FixedPointMathLib } from "solady/src/utils/FixedPointMathLib.sol";

import { USER_1 } from "../../utils/Constants.sol";
import { UsdnLongFarmingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the {IUsdnLongFarming._harvest} function of the USDN long farming
 * @custom:background Given a deployed farming contract and USDN protocol
 */
contract TestUsdnLongFarmingHarvest is UsdnLongFarmingBaseFixture {
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
        posHash = farming.hashPosId(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        farming.deposit(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX, "");
    }

    /**
     * @custom:scenario Reverts when the position is invalid.
     * @custom:given The farming contract with a deposited position.
     * @custom:when The function {IUsdnLongFarming._harvest} is called with an invalid position.
     * @custom:then The call should revert with {UsdnLongFarmingInvalidPosition} error.
     */
    function test_RevertWhen_harvestInvalidPosition() public {
        posHash = farming.hashPosId(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX + 1);
        vm.expectRevert(UsdnLongFarmingInvalidPosition.selector);
        farming.i_harvest(posHash);
    }

    /**
     * @custom:scenario Test {IUsdnLongFarming._harvest} with a liquidated position.
     * @custom:given The farming contract with a deposited position that is liquidated in the USDN protocol.
     * @custom:when The function {IUsdnLongFarming._harvest} is called.
     * @custom:then The position must be liquidated.
     * @custom:and The function return values are correct.
     */
    function test_harvestPositionLiquidate() public {
        uint256 blockNumberSkip = 100;
        vm.roll(block.number + blockNumberSkip);
        usdnProtocol.setPosition(position, DEFAULT_TICK_VERSION, true);

        (bool isLiquidated,) = farming.i_harvest(posHash);
        assertEq(isLiquidated, true, "The position must be liquidated");
    }

    /**
     * @custom:scenario Tests {IUsdnLongFarming._harvest} sends rewards to the position owner.
     * @custom:given The farming contract with a deposited position.
     * @custom:when The function {IUsdnLongFarming._harvest} is called by USER_1 with rewards.
     * @custom:then The rewards is sent to the position owner.
     * @custom:and The function return values are correct.
     */
    function test_harvestSendsRewards() public {
        uint256 rewardsPerBlock = rewardsProvider.getRewardsPerBlock();
        uint256 blockNumberSkip = 100;
        uint256 expectedRewards = rewardsPerBlock * (blockNumberSkip + 1);

        vm.roll(block.number + blockNumberSkip);
        vm.prank(USER_1);
        vm.expectEmit();
        emit Harvest(address(this), posHash, expectedRewards);
        (bool isLiquidated, uint256 newRewardDebt) = farming.i_harvest(posHash);

        assertEq(rewardToken.balanceOf(address(this)), expectedRewards, "The rewards token balance must be updated");
        PositionInfo memory posInfo = farming.getPositionInfo(posHash);
        assertEq(isLiquidated, false, "The position must not be liquidated");
        assertEq(
            newRewardDebt,
            FixedPointMathLib.fullMulDiv(posInfo.shares, farming.getAccRewardPerShare(), farming.SCALING_FACTOR()),
            "The rewards debt must be updated"
        );
    }

    /**
     * @custom:scenario Zero rewards is pending so no rewards are sent.
     * @custom:given The farming contract with a deposited position.
     * @custom:when The function {IUsdnLongFarming._harvest} is called with zero rewards.
     * @custom:then The rewards is not sent to the position owner.
     * @custom:and No logs are emitted.
     */
    function test_harvestZeroRewards() public {
        vm.recordLogs();
        (bool isLiquidated, uint256 newRewardDebt) = farming.i_harvest(posHash);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 0, "No logs must be emitted");
        assertEq(isLiquidated, false, "The position must not be liquidated");
        assertEq(newRewardDebt, 0, "The rewards debt must be zero");
    }
}
