// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { IERC20 } from "@openzeppelin-contracts-5/token/ERC20/IERC20.sol";
import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";
import { MOCK_PYTH_DATA } from "@smardex-usdn-test/unit/Middlewares/utils/Constants.sol";

import { SDEX, SET_PROTOCOL_PARAMS_MANAGER } from "../utils/Constants.sol";
import { UsdnLongFarmingBaseIntegrationFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the {IUsdnLongFarming.withdraw} function of the USDN long farming.
 * @custom:background Given a deployed farming contract and USDN protocol.
 */
contract TestUsdnLongFarmingIntegrationWithdraw is UsdnLongFarmingBaseIntegrationFixture {
    PositionId internal posId1;
    PositionId internal posId2;

    function setUp() public {
        _setUp();

        deal(address(wstETH), address(this), 1e6 ether);
        deal(address(SDEX), address(this), 1e6 ether);
        wstETH.approve(address(protocol), type(uint256).max);
        IERC20(SDEX).approve(address(protocol), type(uint256).max);

        // Disable imbalance checks to facilitate heavy funding
        vm.prank(SET_PROTOCOL_PARAMS_MANAGER);
        protocol.setExpoImbalanceLimits(0, 0, 0, 0, 0, 0);

        uint256 oracleFee = oracleMiddleware.validationCost(MOCK_PYTH_DATA, ProtocolAction.None);
        uint256 securityDeposit = protocol.getSecurityDepositValue();

        _initializeMockPyth();
        oracleFee = oracleMiddleware.validationCost(MOCK_PYTH_DATA, ProtocolAction.ValidateOpenPosition);

        posId1 = _openAndValidatePosition(2.5 ether, 1000 ether, securityDeposit, oracleFee);
        posId2 = _openAndValidatePosition(2.5 ether, 1500 ether, securityDeposit, oracleFee);

        protocol.transferPositionOwnership(posId1, address(farming), "");
        protocol.transferPositionOwnership(posId2, address(farming), "");

        vm.roll(rewardStartingBlock);
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
    function test_OtherPositionNotAffectedByWithdraw() public {
        // Simulate 100 blocks passing
        vm.roll(rewardStartingBlock + 101);
        uint256 expectedTotalRewards = REWARD_PER_BLOCKS * 100;

        uint256 totalSharesBefore = farming.getTotalShares();
        uint256 positionsCountBefore = farming.getPositionsCount();

        uint256 expectedRewardPos1 = farming.pendingRewards(posId1.tick, posId1.tickVersion, posId1.index);

        (, uint256 rewardPos2) = farming.withdraw(posId2.tick, posId2.tickVersion, posId2.index);
        (, uint256 rewardPos1) = farming.harvest(posId1.tick, posId1.tickVersion, posId1.index);

        _assertPositionDeleted(posId2);
        _assertGlobalState(totalSharesBefore, positionsCountBefore);
        assertEq(rewardPos1, expectedRewardPos1, "The reward must not be affected by the second position");
        assertEq(rewardPos2 + rewardPos1, expectedTotalRewards, "Rewards must be calculated correctly");
    }

    function _initializeMockPyth() internal {
        uint128 ethPrice = uint128(wstETH.getWstETHByStETH(DEFAULT_PARAMS.initialPrice)) / 1e10;
        mockPyth.setConf(0);
        mockPyth.setPrice(int64(uint64(ethPrice)));
        mockPyth.setLastPublishTime(block.timestamp - 1);
    }

    function _openAndValidatePosition(uint128 leverage, uint128 amount, uint256 securityDeposit, uint256 oracleFee)
        internal
        returns (PositionId memory positionId)
    {
        (, positionId) = protocol.initiateOpenPosition{ value: securityDeposit }(
            leverage,
            amount,
            type(uint128).max,
            protocol.getMaxLeverage(),
            address(this),
            payable(address(this)),
            type(uint256).max,
            "",
            EMPTY_PREVIOUS_DATA
        );
        _waitDelay();
        protocol.validateOpenPosition{ value: oracleFee }(payable(address(this)), MOCK_PYTH_DATA, EMPTY_PREVIOUS_DATA);
    }

    function _assertPositionDeleted(PositionId memory positionId) internal view {
        assertEq(
            keccak256(abi.encode(farming.getPositionInfo(positionId.tick, positionId.tickVersion, positionId.index))),
            keccak256(abi.encode(PositionInfo(address(0), 0, 0, 0, 0, 0))),
            "The position must be deleted"
        );
    }

    function _assertGlobalState(uint256 totalSharesBefore, uint256 positionsCountBefore) internal view {
        (IUsdnProtocolTypes.Position memory pos,) =
            protocol.getLongPosition(IUsdnProtocolTypes.PositionId(posId2.tick, posId2.tickVersion, posId2.index));
        assertEq(
            farming.getTotalShares(), totalSharesBefore - (pos.totalExpo - pos.amount), "Total shares must decrease"
        );
        assertEq(farming.getPositionsCount(), positionsCountBefore - 1, "Positions count must decrease");
    }

    receive() external payable { }
}
