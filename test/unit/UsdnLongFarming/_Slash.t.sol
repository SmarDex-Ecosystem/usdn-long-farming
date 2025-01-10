// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { Vm } from "forge-std/Vm.sol";

import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";

import { USER_1 } from "../../utils/Constants.sol";
import { UsdnLongFarmingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the {IUsdnLongFarming._slash} function of the USDN long farming
 * @custom:background Given a deployed farming contract and USDN protocol
 */
contract TestUsdnLongFarmingSlash is UsdnLongFarmingBaseFixture {
    IUsdnProtocolTypes.Position internal position;
    bytes32 posHash;
    uint256 blockNumberSkip = 100;
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
        vm.roll(block.number + blockNumberSkip);
        farming.i_updateRewards();
    }

    /**
     * @custom:scenario Tests the slash with a deposited position that was liquidated in the USDN protocol.
     * @custom:given The farming contract with a deposited position.
     * @custom:when The function {IUsdnLongFarming._slash} is called.
     * @custom:then The position is deleted.
     * @custom:and The rewards are transferred to the notifier and the owner of the position.
     * @custom:and A `Slash` event is emitted.
     */
    function test_slash() public {
        uint256 rewards = rewardsProvider.getRewardsPerBlock() * blockNumberSkip;
        uint256 notifierRewardsBps = farming.getNotifierRewardsBps();
        uint256 notifierRewards = rewards * notifierRewardsBps / farming.BPS_DIVISOR();
        uint256 ownerRewards = rewards - notifierRewards;

        usdnProtocol.setPosition(position, DEFAULT_TICK_VERSION, true);
        uint256 totalSharesBefore = farming.getTotalShares();
        uint256 positionsCountBefore = farming.getPositionsCount();

        vm.prank(USER_1);
        vm.expectEmit();
        emit Slash(USER_1, notifierRewards, ownerRewards, DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        farming.i_slash(posHash, address(this), rewards, USER_1, DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);

        assertEq(
            farming.getPositionInfo(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX).owner,
            address(0),
            "The position must be deleted"
        );
        assertEq(rewardToken.balanceOf(address(this)), ownerRewards, "The owner must receive part of the rewards");
        assertEq(rewardToken.balanceOf(USER_1), notifierRewards, "The notifier must receive part of the rewards");

        assertEq(
            farming.getTotalShares(),
            totalSharesBefore - (position.totalExpo - position.amount),
            "The total shares must have decreased"
        );
        assertEq(farming.getPositionsCount(), positionsCountBefore - 1, "The total exposure must have decreased");
    }

    /**
     * @custom:scenario The owner of the deposited position slashes its own liquidated position.
     * @custom:given The farming contract with a deposited position.
     * @custom:when The function {IUsdnLongFarming._slash} is called by the owner of the position.
     * @custom:then The position is deleted.
     * @custom:and The rewards are transferred to the owner of the position.
     * @custom:and A `Slash` event is emitted.
     */
    function test_slashByOwner() public {
        uint256 rewards = rewardsProvider.getRewardsPerBlock() * blockNumberSkip;

        usdnProtocol.setPosition(position, DEFAULT_TICK_VERSION, true);
        uint256 totalSharesBefore = farming.getTotalShares();
        uint256 positionsCountBefore = farming.getPositionsCount();

        vm.expectEmit();
        emit Slash(address(this), 0, rewards, DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        farming.i_slash(
            posHash, address(this), rewards, address(this), DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX
        );

        assertEq(
            farming.getPositionInfo(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX).owner,
            address(0),
            "The position must be deleted"
        );
        assertEq(rewardToken.balanceOf(address(this)), rewards, "The owner must receive all of the rewards");

        assertEq(
            farming.getTotalShares(),
            totalSharesBefore - (position.totalExpo - position.amount),
            "The total shares must have decreased"
        );
        assertEq(farming.getPositionsCount(), positionsCountBefore - 1, "The total exposure must have decreased");
    }

    /**
     * @custom:scenario Tests the slash with a deposited position that was liquidated in the USDN protocol.
     * @custom:given The farming contract with a deposited position.
     * @custom:when The function {IUsdnLongFarming._slash} is called with zero rewards.
     * @custom:then The position is deleted.
     * @custom:and No rewards are transferred.
     * @custom:and A `Slash` event is emitted and no other events.
     */
    function test_slashZeroReward() public {
        usdnProtocol.setPosition(position, DEFAULT_TICK_VERSION, true);
        uint256 totalSharesBefore = farming.getTotalShares();
        uint256 positionsCountBefore = farming.getPositionsCount();

        vm.prank(USER_1);
        vm.expectEmit();
        emit Slash(USER_1, 0, 0, DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        vm.recordLogs();
        farming.i_slash(posHash, address(this), 0, USER_1, DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 1, "Only one event must have been emitted");

        assertEq(
            farming.getPositionInfo(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX).owner,
            address(0),
            "The position must be deleted"
        );
        assertEq(rewardToken.balanceOf(address(this)), 0, "No rewards sent to the owner");
        assertEq(rewardToken.balanceOf(USER_1), 0, "No rewards sent to the notifier");

        assertEq(
            farming.getTotalShares(),
            totalSharesBefore - (position.totalExpo - position.amount),
            "The total amount of shares must have decreased"
        );
        assertEq(farming.getPositionsCount(), positionsCountBefore - 1, "The position count must have decreased");
    }
}
