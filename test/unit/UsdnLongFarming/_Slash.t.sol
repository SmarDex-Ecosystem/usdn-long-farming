// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

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
        posHash = farming.hashPosId(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        usdnProtocol.transferPositionOwnership(
            IUsdnProtocolTypes.PositionId(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX), address(farming), ""
        );
        vm.roll(block.number + blockNumberSkip);
        farming.i_updateRewards();
    }

    /**
     * @custom:scenario Tests the slash with a deposited position was liquidated in the USDN protocol.
     * @custom:given The farming contract with a deposited position.
     * @custom:when The function {IUsdnLongFarming._slash} is called.
     * @custom:then The position is deleted.
     * @custom:and The rewards are transferred to the notifier and the dead address.
     * @custom:and A `Slash` event is emitted.
     */
    function test_slash() public {
        uint256 rewards = 505;
        uint256 notifierRewards = 151;
        uint256 burnedTokens = 354;

        usdnProtocol.setPosition(position, DEFAULT_TICK_VERSION, true);

        vm.prank(USER_1);
        vm.expectEmit();
        emit Slash(USER_1, notifierRewards, burnedTokens, DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        farming.i_slash(posHash, rewards, USER_1, DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);

        assertEq(farming.getPositionInfo(posHash).owner, address(0), "The position must be deleted");
        assertEq(rewardToken.balanceOf(address(this)), 0, "The rewards sent to the notifier and the dead address");
        assertEq(
            rewardToken.balanceOf(farming.DEAD_ADDRESS()),
            burnedTokens,
            "Dead address must receive a part of the rewards"
        );
        assertEq(rewardToken.balanceOf(USER_1), notifierRewards, "The notifier must receive a part of the rewards");
    }

    /**
     * @custom:scenario Tests the slash with a deposited position was liquidated in the USDN protocol.
     * @custom:given The farming contract with a deposited position.
     * @custom:when The function {IUsdnLongFarming._slash} is called with zero rewards.
     * @custom:then The position is deleted.
     * @custom:and The rewards are transferred to the notifier and the dead address.
     * @custom:and A `Slash` event is emitted and no other events.
     */
    function test_slashZeroReward() public {
        usdnProtocol.setPosition(position, DEFAULT_TICK_VERSION, true);

        vm.prank(USER_1);
        vm.expectEmit();
        emit Slash(USER_1, 0, 0, DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        vm.recordLogs();
        farming.i_slash(posHash, 0, USER_1, DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 1, "One event must be emitted");

        assertEq(farming.getPositionInfo(posHash).owner, address(0), "The position must be deleted");
        assertEq(rewardToken.balanceOf(address(this)), 0, "The rewards sent to the notifier and the dead address");
        assertEq(rewardToken.balanceOf(farming.DEAD_ADDRESS()), 0, "Dead address must receive a part of the rewards");
        assertEq(rewardToken.balanceOf(USER_1), 0, "The notifier must receive a part of the rewards");
    }
}
