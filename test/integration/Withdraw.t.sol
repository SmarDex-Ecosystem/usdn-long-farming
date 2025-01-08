// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { IERC20 } from "@openzeppelin-contracts-5/token/ERC20/IERC20.sol";
import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";
import { MOCK_PYTH_DATA } from "@smardex-usdn-test/unit/Middlewares/utils/Constants.sol";

import { SDEX, SET_PROTOCOL_PARAMS_MANAGER, USER_1 } from "../utils/Constants.sol";
import { UsdnLongFarmingBaseIntegrationFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the {IUsdnLongFarming.withdraw} function of the USDN long farming.
 * @custom:background Given a deployed farming contract and USDN protocol.
 */
contract TestForkUsdnLongFarmingIntegrationWithdraw is UsdnLongFarmingBaseIntegrationFixture {
    PositionId internal posId1;
    PositionId internal posId2;
    uint256 oracleFee;

    function setUp() public {
        _setUp();

        wstETH.mintAndApprove(address(this), 1e6 ether, address(protocol), type(uint256).max);

        // Disable imbalance checks to facilitate heavy funding
        vm.prank(SET_PROTOCOL_PARAMS_MANAGER);
        protocol.setExpoImbalanceLimits(0, 0, 0, 0, 0, 0);

        uint256 securityDeposit = protocol.getSecurityDepositValue();

        _setOraclePrices(2000 ether);
        oracleFee = oracleMiddleware.validationCost(MOCK_PYTH_DATA, ProtocolAction.ValidateOpenPosition);

        posId1 = _openAndValidatePosition(2.5 ether, 1000 ether, securityDeposit);
        posId2 = _openAndValidatePosition(2.5 ether, 1500 ether, securityDeposit);

        protocol.transferPositionOwnership(posId1, address(farming), "");
        protocol.transferPositionOwnership(posId2, address(farming), "");
    }

    /**
     * @custom:scenario Tests the {IUsdnLongFarming.withdraw} function with two positions and one withdraw operation.
     * @custom:given There are two positions.
     * @custom:when The function is called to withdraw the second position.
     * @custom:then The call must not revert.
     * @custom:and The user position state must be updated.
     * @custom:and The contract global state must be updated.
     * @custom:and The first position is not affected.
     */
    function test_ForkOtherPositionNotAffectedByWithdraw() public {
        vm.roll(rewardStartingBlock + 101);
        uint256 expectedTotalRewards = REWARD_PER_BLOCKS * 100;
        uint256 totalSharesBefore = farming.getTotalShares();
        uint256 positionsCountBefore = farming.getPositionsCount();

        uint256 expectedRewardPos1 = farming.pendingRewards(posId1.tick, posId1.tickVersion, posId1.index);

        (, uint256 rewardPos2) = farming.withdraw(posId2.tick, posId2.tickVersion, posId2.index);
        (, uint256 rewardPos1) = farming.harvest(posId1.tick, posId1.tickVersion, posId1.index);

        _assertPositionDeleted(posId2);
        (IUsdnProtocolTypes.Position memory pos,) =
            protocol.getLongPosition(IUsdnProtocolTypes.PositionId(posId2.tick, posId2.tickVersion, posId2.index));
        assertEq(
            farming.getTotalShares(), totalSharesBefore - (pos.totalExpo - pos.amount), "Total shares must decrease"
        );
        assertEq(farming.getPositionsCount(), positionsCountBefore - 1, "Positions count must decrease");
        assertEq(rewardPos1, expectedRewardPos1, "The reward must not be affected by the second position");
        assertEq(rewardPos2 + rewardPos1, expectedTotalRewards, "Rewards must be calculated correctly");
    }

    /**
     * @custom:scenario Tests the {IUsdnLongFarming.withdraw} function with two positions and one liquidation operation.
     * @custom:given There are two positions and the second position is liquidated on the protocol.
     * @custom:when The function is called to withdraw the second position.
     * @custom:then The call must not revert.
     * @custom:and The second position must be liquidated instead of withdrawn.
     * @custom:and The contract global state must be updated.
     * @custom:and The first position is not affected.
     */
    function test_ForkOtherPositionNotAffectedByLiquidation() public {
        vm.roll(rewardStartingBlock + 101);
        uint256 expectedTotalRewards = REWARD_PER_BLOCKS * 100;
        uint256 totalSharesBefore = farming.getTotalShares();
        uint256 positionsCountBefore = farming.getPositionsCount();
        uint256 expectedRewardPos1 = farming.pendingRewards(posId1.tick, posId1.tickVersion, posId1.index);
        (IUsdnProtocolTypes.Position memory pos,) =
            protocol.getLongPosition(IUsdnProtocolTypes.PositionId(posId2.tick, posId2.tickVersion, posId2.index));

        skip(oracleMiddleware.getPythRecentPriceDelay());
        _setOraclePrices(1200 ether);
        oracleFee = oracleMiddleware.validationCost(MOCK_PYTH_DATA, ProtocolAction.Liquidation);
        protocol.liquidate{ value: oracleFee }(MOCK_PYTH_DATA);

        uint256 balanceBeforeWithdraw = IERC20(SDEX).balanceOf(USER_1);
        uint256 balanceDeadBeforeWithdraw = IERC20(SDEX).balanceOf(farming.DEAD_ADDRESS());
        vm.prank(USER_1);
        (bool isLiquidate, uint256 rewardPos2) = farming.withdraw(posId2.tick, posId2.tickVersion, posId2.index);
        (, uint256 rewardPos1) = farming.harvest(posId1.tick, posId1.tickVersion, posId1.index);

        assertTrue(isLiquidate, "The position must be liquidated");
        _assertPositionDeleted(posId2);
        assertEq(
            farming.getTotalShares(), totalSharesBefore - (pos.totalExpo - pos.amount), "Total shares must decrease"
        );
        assertEq(rewardPos2, 0, "The reward must be 0");
        assertEq(rewardPos1, expectedRewardPos1, "The reward must not be affected by the second position");
        assertEq(positionsCountBefore - 1, farming.getPositionsCount(), "Positions count must decrease");
        assertEq(
            rewardPos1 + (IERC20(SDEX).balanceOf(USER_1) - balanceBeforeWithdraw)
                + (IERC20(SDEX).balanceOf(farming.DEAD_ADDRESS()) - balanceDeadBeforeWithdraw),
            expectedTotalRewards,
            "Rewards must be calculated correctly"
        );
    }

    /**
     * @custom:scenario Tests the {IUsdnLongFarming.withdraw} function with two positions and one withdraw operation.
     * @custom:given There are two positions and the reward period has not started yet.
     * @custom:when The function is called to withdraw the second position.
     * @custom:then The call must not revert.
     * @custom:and The user position state must be updated.
     * @custom:and The contract global state must be updated.
     * @custom:and The first position is not affected.
     */
    function test_ForkNoRewardSendBeforeRewardStart() public {
        uint256 totalSharesBefore = farming.getTotalShares();
        uint256 positionsCountBefore = farming.getPositionsCount();
        (IUsdnProtocolTypes.Position memory pos,) =
            protocol.getLongPosition(IUsdnProtocolTypes.PositionId(posId2.tick, posId2.tickVersion, posId2.index));

        (, uint256 rewardPos2) = farming.withdraw(posId2.tick, posId2.tickVersion, posId2.index);

        assertEq(rewardPos2, 0, "The reward must be 0");
        _assertPositionDeleted(posId2);
        assertEq(
            farming.getTotalShares(), totalSharesBefore - (pos.totalExpo - pos.amount), "Total shares must decrease"
        );
        assertEq(positionsCountBefore - 1, farming.getPositionsCount(), "Positions count must decrease");
    }

    function _openAndValidatePosition(uint128 amount, uint128 desiredLiqPrice, uint256 securityDeposit)
        internal
        returns (PositionId memory positionId)
    {
        (, positionId) = protocol.initiateOpenPosition{ value: securityDeposit }(
            amount,
            desiredLiqPrice,
            type(uint128).max,
            protocol.getMaxLeverage(),
            address(this),
            payable(this),
            type(uint256).max,
            "",
            EMPTY_PREVIOUS_DATA
        );
        _waitDelay();
        protocol.validateOpenPosition{ value: oracleFee }(payable(this), MOCK_PYTH_DATA, EMPTY_PREVIOUS_DATA);
    }

    function _assertPositionDeleted(PositionId memory positionId) internal view {
        assertEq(
            keccak256(abi.encode(farming.getPositionInfo(positionId.tick, positionId.tickVersion, positionId.index))),
            keccak256(abi.encode(PositionInfo(address(0), 0, 0, 0, 0, 0))),
            "The position must be deleted"
        );
    }

    receive() external payable { }
}
