// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { Vm } from "forge-std/Vm.sol";

import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";

import { USER_1 } from "../../utils/Constants.sol";
import { UsdnLongFarmingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the {IUsdnLongFarming.withdraw} function of the USDN long farming
 * @custom:background Given a deployed farming contract and USDN protocol
 */
contract TestUsdnLongFarmingWithdraw is UsdnLongFarmingBaseFixture {
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
     * @custom:scenario Tests the {IUsdnLongFarming.withdraw} function with a valid position.
     * @custom:when The function is called.
     * @custom:then The call must not revert.
     * @custom:and The user position state must be updated.
     * @custom:and The contract global state must be updated.
     */
    function test_withdraw() public {
        uint256 blockNumberSkip = 100;
        vm.roll(block.number + blockNumberSkip);

        uint256 totalSharesBefore = farming.getTotalShares();
        uint256 positionsCountBefore = farming.getPositionsCount();

        vm.expectEmit();
        emit Withdraw(address(this), DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        (bool isLiquidated_, uint256 rewards_) = farming.withdraw(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        // return values
        assertEq(rewards_, 505, "The token is transferred to the user");
        assertFalse(isLiquidated_, "The position must not be liquidated");
        // position state
        _assertPositionDeleted(posHash);
        assertEq(rewardToken.balanceOf(address(this)), 505, "The token is transferred to the user");
        // USDN state
        (IUsdnProtocolTypes.Position memory USDNPosition,) = farming.USDN_PROTOCOL().getLongPosition(
            IUsdnProtocolTypes.PositionId(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX)
        );
        assertEq(USDNPosition.user, address(this), "The position must be deleted");
        // global state
        _assertGlobalState(totalSharesBefore, positionsCountBefore);
    }

    /**
     * @custom:scenario Tests the {IUsdnLongFarming.withdraw} function reverts when the caller is not the owner.
     * @custom:when The function is called.
     * @custom:then The call should revert with {IUsdnLongFarmingErrors.UsdnLongFarmingInvalidPosition}.
     */
    function test_revertWhen_notOwnerWithdraw() public {
        vm.prank(USER_1);
        vm.expectRevert(UsdnLongFarmingInvalidCaller.selector);
        farming.withdraw(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
    }

    /**
     * @custom:scenario Tests the {IUsdnLongFarming.withdraw} function sends rewards to the msg.sender and the dead
     * address and liquidates the position.
     * @custom:when The function is called and the position is liquidated.
     * @custom:then The position must be liquidated.
     * @custom:and The return values must be correct.
     */
    function test_withdrawPositionLiquidate() public {
        uint256 blockNumberSkip = 100;
        vm.roll(block.number + blockNumberSkip);
        usdnProtocol.setPosition(position, DEFAULT_TICK_VERSION, true);

        vm.prank(USER_1);
        vm.expectEmit();
        emit Slash(USER_1, 151, 354, DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        (bool isLiquidated_, uint256 rewards_) = farming.withdraw(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);

        // return values
        assertTrue(isLiquidated_, "The position must be liquidated");
        assertEq(rewards_, 0, "The token is transferred to the user");
        // position deleted
        PositionInfo memory posInfo = farming.getPositionInfo(posHash);
        assertEq(posInfo.rewardDebt, 0, "The reward debt must deleted");
        assertEq(posInfo.owner, address(0), "The owner must be deleted");
        // tokens sent
        assertEq(rewardToken.balanceOf(address(this)), 0, "The rewards sent to the notifier and the dead address");
        assertEq(rewardToken.balanceOf(farming.DEAD_ADDRESS()), 354, "Dead address must receive a part of the rewards");
        assertEq(rewardToken.balanceOf(USER_1), 151, "The notifier must receive a part of the rewards");
    }

    /**
     * @custom:scenario Tests the {IUsdnLongFarming.withdraw} function sends zero rewards to the user.
     * @custom:when The function is called.
     * @custom:then The user must not receive rewards.
     * @custom:and The user position state must be updated.
     * @custom:and The contract global state must be updated.
     * @custom:and No Harvest event is emitted.
     */
    function test_withdrawZeroRewards() public {
        uint256 totalSharesBefore = farming.getTotalShares();
        uint256 positionsCountBefore = farming.getPositionsCount();

        vm.expectEmit();
        emit Withdraw(address(this), DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        vm.recordLogs();
        (bool isLiquidated_, uint256 rewards_) = farming.withdraw(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);

        // no Harvest event emitted
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 1, "One log must be emitted");
        assertEq(logs[0].topics[0], Withdraw.selector, "The log topic must be Withdraw and not Harvest");

        // return values
        assertEq(rewards_, 0, "The user must not receive rewards");
        assertFalse(isLiquidated_, "The position must not be liquidated");
        // position state
        _assertPositionDeleted(posHash);
        assertEq(farming.REWARD_TOKEN().balanceOf(address(this)), 0, "The user must not receive rewards");
        // USDN state
        (IUsdnProtocolTypes.Position memory USDNPosition,) = farming.USDN_PROTOCOL().getLongPosition(
            IUsdnProtocolTypes.PositionId(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX)
        );
        assertEq(USDNPosition.user, address(this), "The position must be deleted");
        // global state
        _assertGlobalState(totalSharesBefore, positionsCountBefore);
    }

    function _assertPositionDeleted(bytes32 _posHash) internal view {
        assertEq(
            keccak256(abi.encode(farming.getPositionInfo(_posHash))),
            keccak256(abi.encode(PositionInfo(address(0), 0, 0, 0, 0, 0))),
            "The position must be deleted"
        );
    }

    function _assertGlobalState(uint256 totalSharesBefore, uint256 positionsCountBefore) internal view {
        assertEq(
            farming.getTotalShares(),
            totalSharesBefore - (position.totalExpo - position.amount),
            "The total shares must be decreased"
        );
        assertEq(farming.getPositionsCount(), positionsCountBefore - 1, "The total exposure must be decreased");
    }
}
