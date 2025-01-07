// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { MOCK_PYTH_DATA } from "@smardex-usdn-test/unit/Middlewares/utils/Constants.sol";

import { UsdnLongFarmingIntegrationFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the `transferPositionOwnership` function of the USDN protocol to the USDN long farming.
 * @custom:background Given a deployed farming contract and USDN protocol.
 */
contract TestForkTransferPositionOwnershipUsdnLongFarming is UsdnLongFarmingIntegrationFixture {
    uint128 internal BASE_AMOUNT = 2 ether;
    PositionId internal posId;

    function setUp() public {
        _setUp();
        wstETH.mintAndApprove(address(this), 10_000 ether, address(protocol), type(uint256).max);

        bool isInitiated;
        (isInitiated, posId) = protocol.initiateOpenPosition{ value: protocol.getSecurityDepositValue() }(
            BASE_AMOUNT,
            params.initialLiqPrice,
            type(uint128).max,
            protocol.getMaxLeverage(),
            address(this),
            payable(this),
            type(uint256).max,
            "",
            EMPTY_PREVIOUS_DATA
        );

        assertTrue(isInitiated, "user USDN protocol position is not initiated");
        _waitDelay();
    }

    /**
     * @custom:scenario Tests the `transferPositionOwnership` function to the USDN long farming.
     * @custom:given A user validated USDN protocol position.
     * @custom:when The function is called.
     * @custom:then The USDN long farming position must be stored.
     */
    function test_ForkTransferPositionOwnershipLongFarming() public {
        protocol.validateOpenPosition(payable(this), MOCK_PYTH_DATA, EMPTY_PREVIOUS_DATA);

        (Position memory pos,) = protocol.getLongPosition(posId);

        protocol.transferPositionOwnership(posId, address(farming), "");

        PositionInfo memory posInfo = farming.getPositionInfo(posId.tick, posId.tickVersion, posId.index);

        assertEq(posInfo.owner, address(this), "The position owner must be the user");
        assertGt(posInfo.shares, 0, "The position shares must be positive");
        assertEq(posInfo.shares, pos.totalExpo - pos.amount, "The position shares must be different");
    }

    /**
     * @custom:scenario Tests the `transferPositionOwnership` function to the USDN long farming for a pending position.
     * @custom:given A user USDN protocol position pending validation.
     * @custom:when The function is called.
     * @custom:then The call should revert with {UsdnLongFarmingPendingPosition} error.
     */
    function test_RevertWhen_ForkTransferPositionOwnershipPendingLongFarming() public {
        vm.expectRevert(UsdnLongFarmingPendingPosition.selector);
        protocol.transferPositionOwnership(posId, address(farming), "");
    }

    receive() external payable { }
}
