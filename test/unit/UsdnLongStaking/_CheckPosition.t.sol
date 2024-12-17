// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";

import { UsdnLongStakingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the internal {_checkPosition} of the USDN long staking.
 * @custom:background Given a deployed staking contract and USDN protocol.
 */
contract TestUsdnLongStakingCheckPosition is UsdnLongStakingBaseFixture {
    IUsdnProtocolTypes.Position internal position;

    function setUp() public {
        _setUp();

        position = IUsdnProtocolTypes.Position({
            validated: true,
            timestamp: uint40(block.timestamp),
            user: address(this),
            totalExpo: 1,
            amount: 0
        });
    }

    /**
     * @custom:scenario Tests the {_checkPosition} function with a valid position.
     * @custom:when The function is called.
     * @custom:then The call should not revert.
     */
    function test_checkPosition() public view {
        staking.i_checkPosition(position);
    }

    /**
     * @custom:scenario Tests the {_checkPosition} function with a position already owned by the staking.
     * @custom:when The function is called.
     * @custom:then The call should revert with {UsdnLongStakingAlreadyDeposited}.
     */
    function test_RevertWhen_checkPositionOwned() public {
        position.user = address(staking);
        vm.expectRevert(UsdnLongStakingAlreadyDeposited.selector);
        staking.i_checkPosition(position);
    }

    /**
     * @custom:scenario Tests the {_checkPosition} function with a pending position.
     * @custom:when The function is called.
     * @custom:then The call should revert with {UsdnLongStakingPendingPosition}.
     */
    function test_RevertWhen_checkPositionPending() public {
        position.validated = false;
        vm.expectRevert(UsdnLongStakingPendingPosition.selector);
        staking.i_checkPosition(position);
    }
}
