// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";

import { UsdnLongFarmingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the internal {UsdnLongFarming._checkPosition} function of the USDN long farming.
 * @custom:background Given a deployed farming contract and USDN protocol.
 */
contract TestUsdnLongFarmingCheckPosition is UsdnLongFarmingBaseFixture {
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
     * @custom:scenario Tests the {UsdnLongFarming._checkPosition} function with a valid position.
     * @custom:when The function is called.
     * @custom:then The call should not revert.
     */
    function test_checkPosition() public view {
        farming.i_checkPosition(position);
    }

    /**
     * @custom:scenario Tests the {UsdnLongFarming._checkPosition} function with a position already owned by the
     * farming.
     * @custom:when The function is called.
     * @custom:then The call should revert with {IUsdnLongFarmingErrors.UsdnLongFarmingAlreadyDeposited}.
     */
    function test_RevertWhen_checkPositionOwned() public {
        position.user = address(farming);
        vm.expectRevert(UsdnLongFarmingAlreadyDeposited.selector);
        farming.i_checkPosition(position);
    }

    /**
     * @custom:scenario Tests the {UsdnLongFarming._checkPosition} function with a pending position.
     * @custom:when The function is called.
     * @custom:then The call should revert with {IUsdnLongFarmingErrors.UsdnLongFarmingPendingPosition}.
     */
    function test_RevertWhen_checkPositionPending() public {
        position.validated = false;
        vm.expectRevert(UsdnLongFarmingPendingPosition.selector);
        farming.i_checkPosition(position);
    }
}
