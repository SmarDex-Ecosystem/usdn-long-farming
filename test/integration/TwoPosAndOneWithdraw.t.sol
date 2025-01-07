// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { Vm } from "forge-std/Vm.sol";

import { IERC20 } from "@openzeppelin-contracts-5/token/ERC20/IERC20.sol";
import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";

import { SDEX, SET_PROTOCOL_PARAMS_MANAGER } from "../utils/Constants.sol";
import { UsdnLongFarmingBaseIntegrationFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the {IUsdnLongFarming.withdraw} function of the USDN long farming
 * @custom:background Given a deployed farming contract and USDN protocol
 */
contract TestUsdnLongFarmingTwoPosAndOneWithdraw is UsdnLongFarmingBaseIntegrationFixture {
    bytes32 posHash;
    bytes constant MOCK_PYTH_DATA = hex"504e41550000000000000000000000000000000000000000000000000000000011";
    PositionId posId1;
    PositionId posId2;
    uint256 constant OPEN_POSITION_AMOUNT = 3 ether;
    uint256 constant DESIRED_LIQUIDATION = 2500 ether;
    uint256 internal _securityOpenPosition;
    uint256 oracleFee;

    function setUp() public {
        _setUp();

        deal(address(wstETH), address(this), 1e6 ether);
        deal(address(SDEX), address(this), 1e6 ether);
        wstETH.approve(address(protocol), type(uint256).max);
        IERC20(SDEX).approve(address(protocol), type(uint256).max);

        // disable imbalance checks to make it easier to have heavy fundings
        vm.prank(SET_PROTOCOL_PARAMS_MANAGER);
        protocol.setExpoImbalanceLimits(0, 0, 0, 0, 0, 0);
        oracleFee = oracleMiddleware.validationCost(MOCK_PYTH_DATA, ProtocolAction.None);

        _securityOpenPosition = protocol.getSecurityDepositValue();

        {
            uint128 ethPrice = uint128(wstETH.getWstETHByStETH(DEFAULT_PARAMS.initialPrice)) / 1e10;
            mockPyth.setConf(0);
            mockPyth.setPrice(int64(uint64(ethPrice)));
            mockPyth.setLastPublishTime(block.timestamp - 1);
        }
        oracleFee = oracleMiddleware.validationCost(MOCK_PYTH_DATA, ProtocolAction.ValidateOpenPosition);

        (, posId1) = protocol.initiateOpenPosition{ value: _securityOpenPosition }(
            2.5 ether,
            1000 ether,
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

        (, posId2) = protocol.initiateOpenPosition{ value: _securityOpenPosition }(
            2.5 ether,
            1500 ether,
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

        protocol.transferPositionOwnership(posId1, address(farming), "");
        protocol.transferPositionOwnership(posId2, address(farming), "");

        // start farming
        vm.roll(block.number + 10);
    }

    /**
     * @custom:scenario Tests the {IUsdnLongFarming.withdraw} function with a valid position.
     * @custom:given There are two positions.
     * @custom:when The function is called to withdraw the first position.
     * @custom:then The call must not revert.
     * @custom:and The user position state must be updated.
     * @custom:and The contract global state must be updated.
     * @custom:and The second position does not effected.
     */
    function test_OtherPositionNotAffectedByWithdraw() public {
        // 100 blocks passed
        vm.roll(block.number + 101);
        uint256 expectedRewards = REWARD_PER_BLOCKS * 100;

        uint256 totalSharesBefore = farming.getTotalShares();
        uint256 positionsCountBefore = farming.getPositionsCount();

        uint256 expectedRewardPos1 = farming.pendingRewards(posId1.tick, posId1.tickVersion, posId1.index);

        (, uint256 rewardPos2) = farming.withdraw(posId2.tick, posId2.tickVersion, posId2.index);
        _assertPositionDeleted();
        _assertGlobalState(totalSharesBefore, positionsCountBefore);

        (, uint256 rewardPos1) = farming.harvest(posId1.tick, posId1.tickVersion, posId1.index);
        assertEq(rewardPos1, expectedRewardPos1, "The reward must be not affected by the second position");
        assertEq(rewardPos2 + rewardPos1, expectedRewards, "The reward must be calculated correctly");
    }

    function _assertPositionDeleted() internal view {
        assertEq(
            keccak256(abi.encode(farming.getPositionInfo(posId2.tick, posId2.tickVersion, posId2.index))),
            keccak256(abi.encode(PositionInfo(address(0), 0, 0, 0, 0, 0))),
            "The position must be deleted"
        );
    }

    function _assertGlobalState(uint256 totalSharesBefore, uint256 positionsCountBefore) internal view {
        (IUsdnProtocolTypes.Position memory pos,) =
            protocol.getLongPosition(IUsdnProtocolTypes.PositionId(posId2.tick, posId2.tickVersion, posId2.index));
        assertEq(
            farming.getTotalShares(),
            totalSharesBefore - (pos.totalExpo - pos.amount),
            "The total shares must be decreased"
        );
        assertEq(farming.getPositionsCount(), positionsCountBefore - 1, "The total exposure must be decreased");
    }

    receive() external payable { }
}
