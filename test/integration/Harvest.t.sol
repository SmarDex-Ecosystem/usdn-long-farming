// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { IERC20 } from "@openzeppelin-contracts-5/token/ERC20/IERC20.sol";
import { MOCK_PYTH_DATA } from "@smardex-usdn-test/unit/Middlewares/utils/Constants.sol";

import { SDEX, USER_1 } from "../utils/Constants.sol";
import { UsdnLongFarmingIntegrationFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the {IUsdnLongFarming.harvest} function of the USDN long farming.
 * @custom:background Given a deployed farming contract and USDN protocol.
 */
contract TestForkUsdnLongFarmingIntegrationWithdraw is UsdnLongFarmingIntegrationFixture {
    PositionId internal posId1;
    PositionId internal posId2;
    uint256 oracleFee;

    function setUp() public {
        _setUp();

        wstETH.mintAndApprove(address(this), 1e6 ether, address(protocol), type(uint256).max);

        _setOraclePrices(2000 ether);

        posId1 = _openAndValidatePosition(2.5 ether, 1500 ether);
        posId2 = _openAndValidatePosition(2.5 ether, 1000 ether);

        protocol.transferPositionOwnership(posId1, address(farming), "");
        protocol.transferPositionOwnership(posId2, address(farming), "");
    }

    /**
     * @custom:scenario Tests the {IUsdnLongFarming.harvest} function with two positions and one harvest operation.
     * @custom:given There are two positions.
     * @custom:when The function is called to harvest the first position.
     * @custom:then The call must not revert.
     * @custom:and The user receives the rewards.
     * @custom:and The other position is not affected.
     */
    function test_ForkOtherPositionNotAffectedByHarvest() public {
        vm.roll(rewardStartingBlock + 101);
        uint256 expectedTotalRewards = REWARD_PER_BLOCKS * (block.number - 1 - rewardStartingBlock);

        uint256 expectedRewardPos1 = farming.pendingRewards(posId1.tick, posId1.tickVersion, posId1.index);
        uint256 expectedRewardPos2 = farming.pendingRewards(posId2.tick, posId2.tickVersion, posId2.index);

        (, uint256 rewardPos1) = farming.harvest(posId1.tick, posId1.tickVersion, posId1.index);
        uint256 rewardPos2 = farming.pendingRewards(posId2.tick, posId2.tickVersion, posId2.index);

        assertEq(rewardPos1, expectedRewardPos1, "The reward must not be affected by the first position");
        assertEq(rewardPos2, expectedRewardPos2, "The reward must not be affected by the second position");
        assertEq(rewardPos2 + rewardPos1, expectedTotalRewards, "Rewards must be calculated correctly");
    }

    /**
     * @custom:scenario Tests the {IUsdnLongFarming.harvest} function with two positions and one liquidation operation.
     * @custom:given There are two positions and the first position is liquidated on the protocol.
     * @custom:when The function is called to harvest the first position.
     * @custom:then The call must not revert.
     * @custom:and The first position must be liquidated instead of received rewards.
     * @custom:and The user receives the liquidation reward.
     * @custom:and The other position is not affected.
     */
    function test_ForkOtherPositionNotAffectedByLiquidationHarvest() public {
        vm.roll(rewardStartingBlock + 101);
        uint256 expectedTotalRewards = REWARD_PER_BLOCKS * (block.number - 1 - rewardStartingBlock);
        uint256 expectedRewardPos2 = farming.pendingRewards(posId2.tick, posId2.tickVersion, posId2.index);

        skip(oracleMiddleware.getPythRecentPriceDelay());
        _setOraclePrices(1200 ether);
        oracleFee = oracleMiddleware.validationCost(MOCK_PYTH_DATA, ProtocolAction.Liquidation);
        protocol.liquidate{ value: oracleFee }(MOCK_PYTH_DATA);

        uint256 balanceNotifierBeforeWithdraw = IERC20(SDEX).balanceOf(USER_1);
        uint256 balanceOwnerBeforeWithdraw = IERC20(SDEX).balanceOf(address(this));
        vm.prank(USER_1);
        (bool isLiquidate, uint256 rewardPos1) = farming.harvest(posId1.tick, posId1.tickVersion, posId1.index);
        uint256 rewardNotifier = IERC20(SDEX).balanceOf(USER_1) - balanceNotifierBeforeWithdraw;
        uint256 rewardOwner = IERC20(SDEX).balanceOf(address(this)) - balanceOwnerBeforeWithdraw;
        uint256 rewardPos2 = farming.pendingRewards(posId2.tick, posId2.tickVersion, posId2.index);

        assertTrue(isLiquidate, "The position must be liquidated");
        assertEq(rewardPos1, 0, "The reward must be 0");
        assertEq(rewardPos2, expectedRewardPos2, "The reward must not be affected by the second position");
        assertEq(
            rewardPos2 + rewardNotifier + rewardOwner, expectedTotalRewards, "Rewards must be calculated correctly"
        );
    }

    /**
     * @custom:scenario Tests the {IUsdnLongFarming.harvest} function with two positions and one harvest operation.
     * @custom:given There are two positions and the reward period has not started yet.
     * @custom:when The function is called to harvest the second position.
     * @custom:then The call must not revert.
     * @custom:and The user receives no rewards.
     */
    function test_ForkNoRewardSendBeforeRewardStartHarvest() public {
        (, uint256 rewardPos2) = farming.harvest(posId2.tick, posId2.tickVersion, posId2.index);

        assertEq(rewardPos2, 0, "The reward must be 0");
    }

    function _openAndValidatePosition(uint128 amount, uint128 desiredLiqPrice)
        internal
        returns (PositionId memory positionId)
    {
        (, positionId) = protocol.initiateOpenPosition{ value: protocol.getSecurityDepositValue() }(
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
        protocol.validateOpenPosition(payable(this), MOCK_PYTH_DATA, EMPTY_PREVIOUS_DATA);
    }

    receive() external payable { }
}
