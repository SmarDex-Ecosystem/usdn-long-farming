// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";

import { UsdnLongFarmingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the {IUsdnLongFarming.pendingRewards} function of the USDN long farming
 * @custom:background Given a deployed farming contract and USDN protocol
 */
contract TestUsdnLongFarmingPendingRewards is UsdnLongFarmingBaseFixture {
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
        farming.setTotalShares(1);
        usdnProtocol.transferPositionOwnership(
            IUsdnProtocolTypes.PositionId(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX), address(farming), ""
        );
    }

    /**
     * @custom:scenario Tests the {IUsdnLongFarming.pendingRewards} function with an invalid position.
     * @custom:when The function is called.
     * @custom:then The value returned must be 0.
     */
    function test_pendingRewardInvalidPosition() public view {
        assertEq(farming.pendingRewards(0, 0, 0), 0, "The pending rewards must be equal 0");
    }

    /**
     * @custom:scenario Tests the {IUsdnLongFarming.pendingRewards} function result
     * for a position without pending rewards.
     * @custom:when The function is called.
     * @custom:then The value returned must be equal 0.
     */
    function test_pendingRewardsWithoutRewards() public view {
        uint256 pendingRewards = farming.pendingRewards(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        assertEq(pendingRewards, 0, "The pending rewards must be equal 0");
    }

    /**
     * @custom:scenario Tests the {IUsdnLongFarming.pendingRewards} function result for a position with pending rewards.
     * @custom:when The function is called.
     * @custom:then The value returned must be positive.
     */
    function test_pendingRewardsWithRewards() public {
        vm.roll(block.number + 1);
        uint256 pendingRewards = farming.pendingRewards(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        assertGt(pendingRewards, 0, "The pending rewards must be positive");
    }

    /**
     * @custom:scenario Compares the {IUsdnLongFarming.pendingRewards} function result
     * of a position with pending rewards with the received amount of rewards.
     * @custom:when The {IUsdnLongFarming.pendingRewards} function is called.
     * @custom:then The value returned must be positive.
     * @custom:when The {IUsdnLongFarming.harvest} function is called.
     * @custom:then The amount of rewards sent must be equal to the pending rewards value.
     */
    function test_pendingRewardsEqualReceivedRewards() public {
        vm.roll(block.number + 1);
        uint256 pendingRewards = farming.pendingRewards(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        (bool isLiquidated, uint256 receivedRewards) =
            farming.harvest(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        assertFalse(isLiquidated, "The position must be active");
        assertEq(pendingRewards, receivedRewards, "The pending rewards must be equal to the received rewards");
    }

    /**
     * @custom:scenario Tests the {IUsdnLongFarming.pendingRewards} function result after harvest.
     * @custom:when The function is called.
     * @custom:then The value returned must be equal 0.
     */
    function test_pendingRewardsEqualZero() public {
        test_pendingRewardsEqualReceivedRewards();
        assertEq(
            farming.pendingRewards(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX),
            0,
            "The pending rewards must be equal 0"
        );
    }
}
