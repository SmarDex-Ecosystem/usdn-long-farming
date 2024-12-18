// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";

import { UsdnLongFarmingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the {IUsdnLongFarming.deposit} function of the USDN long farming
 * @custom:background Given a deployed farming contract and USDN protocol
 */
contract TestUsdnLongFarmingDeposit is UsdnLongFarmingBaseFixture {
    IUsdnProtocolTypes.Position internal position;
    int24 internal constant DEFAULT_TICK = 1234;
    uint256 internal constant DEFAULT_TICK_VERSION = 123;
    uint256 internal constant DEFAULT_INDEX = 12;

    bytes32 internal _defaultPosHash;

    function setUp() public {
        _setUp();

        position = IUsdnProtocolTypes.Position({
            validated: true,
            timestamp: uint40(block.timestamp),
            user: address(this),
            totalExpo: 1,
            amount: 0
        });

        usdnProtocol.setPosition(position);
        _defaultPosHash = farming.hashPosId(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
    }

    /**
     * @custom:scenario Tests the {IUsdnLongFarming.deposit} function with a valid position.
     * @custom:when The function is called.
     * @custom:then The call must not revert.
     * @custom:and The user position state must be updated.
     * @custom:and The contract global state must be updated.
     */
    function test_deposit() public {
        // fill a previous share to the farming
        uint256 previousTotalShares = 1;
        farming.setTotalShares(previousTotalShares);

        vm.expectEmit();
        emit Deposit(address(this), DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        farming.deposit(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX, "");

        // user position state
        PositionInfo memory posInfo = farming.getPositionInfo(_defaultPosHash);
        assertEq(posInfo.owner, address(this), "The owner must be the user");
        assertEq(posInfo.tick, DEFAULT_TICK, "The tick must be the default tick");
        assertEq(posInfo.tickVersion, DEFAULT_TICK_VERSION, "The tick version must be the default tick version");
        assertEq(posInfo.index, DEFAULT_INDEX, "The index must be the default index");
        assertEq(
            posInfo.shares,
            position.totalExpo - position.amount,
            "The shares must be equal to `initial totalExpo - initial amount`"
        );
        assertEq(
            posInfo.rewardDebt,
            farming.getAccRewardPerShare() * posInfo.shares / farming.SCALING_FACTOR(),
            "The rewardDebt must be updated"
        );

        // global contract state
        assertEq(
            farming.getTotalShares(),
            posInfo.shares + previousTotalShares,
            "The total shares must be equal to `user shares + previous shares`"
        );
        assertEq(farming.getPositionsCount(), 1, "The position count must be 1");
        assertEq(farming.getLastRewardBlock(), block.number, "The last reward block must be updated");
        assertGt(
            rewardToken.balanceOf(address(farming)),
            0,
            "The rewards token balance of the farming contract must be positive"
        );
        assertEq(
            farming.getAccRewardPerShare(),
            rewardToken.balanceOf(address(farming)) * farming.SCALING_FACTOR() / previousTotalShares,
            "The rewards by share accumulator must be updated"
        );
    }
}
