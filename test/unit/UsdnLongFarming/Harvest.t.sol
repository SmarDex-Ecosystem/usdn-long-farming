// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { Vm } from "forge-std/Vm.sol";

import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";
import { FixedPointMathLib } from "solady/src/utils/FixedPointMathLib.sol";

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
        posHash = farming.hashPosId(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        farming.deposit(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX, "");
    }

    /**
     * @custom:scenario Tests the harvest with the position info updated.
     * @custom:given The farming contract with a deposited position.
     * @custom:when The function {IUsdnLongFarming.harvest} is called.
     * @custom:then The reward debt is updated.
     */
    function test_harvestPosInfoUpdated() public {
        uint256 blockNumberSkip = 100;
        vm.roll(block.number + blockNumberSkip);

        vm.prank(USER_1);
        farming.harvest(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        PositionInfo memory posInfo = farming.getPositionInfo(posHash);
        assertEq(
            posInfo.rewardDebt,
            FixedPointMathLib.fullMulDiv(posInfo.shares, farming.getAccRewardPerShare(), farming.SCALING_FACTOR()),
            "The reward debt must be updated"
        );
    }

    /**
     * @custom:scenario `rewardDebt` is ignored when liquidating the position.
     * @custom:given The farming contract with a position marked as liquidated.
     * @custom:when The function {IUsdnLongFarming.harvest} is called and the position is liquidated.
     * @custom:then The reward debt is ignored and set to zero because the position was deleted.
     * @custom:and The position owner is deleted.
     */
    function test_harvestPositionLiquidateAndRewardDebtIgnore() public {
        uint256 blockNumberSkip = 100;
        vm.roll(block.number + blockNumberSkip);
        usdnProtocol.setPosition(position, DEFAULT_TICK_VERSION, true);

        vm.prank(USER_1);
        farming.harvest(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);

        PositionInfo memory posInfo = farming.getPositionInfo(posHash);
        assertEq(posInfo.rewardDebt, 0, "The reward debt must deleted");
        assertEq(posInfo.owner, address(0), "The owner must be deleted");
    }

    /**
     * @custom:scenario Zero rewards is pending so no rewards are sent.
     * @custom:given The farming contract with a deposited position.
     * @custom:when The function {IUsdnLongFarming.harvest} is called with zero rewards.
     * @custom:then The rewards is not sent to the position owner.
     * @custom:and No logs are emitted.
     */
    function test_harvestZeroRewards() public {
        vm.recordLogs();
        (bool isLiquidated) = farming.harvest(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 0, "No logs must be emitted");
        assertEq(isLiquidated, false, "The position must not be liquidated");
    }
}
