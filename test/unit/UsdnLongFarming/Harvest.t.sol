// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { Vm } from "forge-std/Vm.sol";

import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";
import { FixedPointMathLib } from "solady-0.0.281/utils/FixedPointMathLib.sol";

import { USER_1 } from "../../utils/Constants.sol";
import { UsdnLongFarmingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the {IUsdnLongFarming.harvest} function of the USDN long farming
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
        posHash = farming.i_hashPositionId(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        usdnProtocol.transferPositionOwnership(
            IUsdnProtocolTypes.PositionId(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX), address(farming), ""
        );
    }

    /**
     * @custom:scenario Tests the harvest with the position info updated.
     * @custom:given The farming contract with a deposited position.
     * @custom:when The function {IUsdnLongFarming.harvest} is called.
     * @custom:then The reward debt is updated.
     * @custom:and The token balance of the user is updated.
     */
    function test_harvestPosInfoUpdated() public {
        vm.roll(block.number + 100);

        vm.prank(USER_1);
        vm.expectEmit();
        emit Harvest(address(this), 505, DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        farming.harvest(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);

        PositionInfo memory posInfo = farming.getPositionInfo(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        assertEq(
            posInfo.rewardDebt,
            FixedPointMathLib.fullMulDiv(posInfo.shares, farming.getAccRewardPerShare(), farming.SCALING_FACTOR()),
            "The reward debt must be updated"
        );
        assertEq(
            farming.REWARD_TOKEN().balanceOf(address(this)), posInfo.rewardDebt, "The token balance must be updated"
        );
    }

    /**
     * @custom:scenario `rewardDebt` is ignored when liquidating the position.
     * @custom:given The farming contract with a position marked as liquidated.
     * @custom:when The function {IUsdnLongFarming.harvest} is called and the position is liquidated.
     * @custom:then The reward debt is ignored and set to zero because the position was deleted.
     * @custom:and The position owner is deleted.
     * @custom:and The rewards are transferred to the notifier and owner of the position.
     * @custom:and A `Slash` event is emitted.
     */
    function test_harvestPositionLiquidateAndRewardDebtIgnore() public {
        vm.roll(block.number + 100);
        usdnProtocol.setPosition(position, DEFAULT_TICK_VERSION, true);

        uint256 totalSharesBefore = farming.getTotalShares();
        uint256 positionsCountBefore = farming.getPositionsCount();

        vm.prank(USER_1);
        vm.expectEmit();
        emit Slash(USER_1, 151, 354, DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        farming.harvest(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);

        PositionInfo memory posInfo = farming.getPositionInfo(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        assertEq(posInfo.rewardDebt, 0, "The reward debt must deleted");
        assertEq(posInfo.owner, address(0), "The owner must be deleted");

        assertEq(rewardToken.balanceOf(address(this)), 354, "The owner must receive a part of the rewards");
        assertEq(rewardToken.balanceOf(USER_1), 151, "The notifier must receive a part of the rewards");

        assertEq(
            farming.getTotalShares(),
            totalSharesBefore - (position.totalExpo - position.amount),
            "The total shares must be decreased"
        );
        assertEq(farming.getPositionsCount(), positionsCountBefore - 1, "The total exposure must be decreased");
    }

    /**
     * @custom:scenario Tests the {IUsdnLongFarming.harvest} function sends zero rewards to the user.
     * @custom:when The function is called.
     * @custom:then The user must not receive rewards.
     * @custom:and The farming balance must not decrease.
     * @custom:and No logs are emitted.
     */
    function test_harvestZeroRewards() public {
        vm.recordLogs();
        (bool isLiquidated_, uint256 rewards_) = farming.harvest(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        assertEq(farming.REWARD_TOKEN().balanceOf(address(this)), 0, "The user must not receive rewards");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 0, "No logs must be emitted");
        assertFalse(isLiquidated_, "The position must not be liquidated");
        assertEq(rewards_, 0, "The rewards must be zero");
    }
}
