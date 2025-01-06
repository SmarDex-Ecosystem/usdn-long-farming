// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";

import { UsdnLongFarmingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the {IUsdnLongFarming.ownershipCallback} function of the USDN long farming
 * @custom:background Given a deployed farming contract and USDN protocol
 */
contract TestUsdnLongFarmingOwnershipCallback is UsdnLongFarmingBaseFixture {
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

        usdnProtocol.setPosition(position, DEFAULT_TICK_VERSION, false);
        _defaultPosHash = farming.hashPosId(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
    }

    /**
     * @custom:scenario Tests the {IUsdnLongFarming.ownershipCallback} function with an invalid caller.
     * @custom:when The function is called.
     * @custom:then The call must revert with {IUsdnLongFarmingErrors.UsdnLongFarmingInvalidCaller}.
     */
    function test_RevertWhen_ownershipCallbackInvalidCaller() public {
        vm.expectRevert(UsdnLongFarmingInvalidCaller.selector);
        farming.ownershipCallback(address(0), IUsdnProtocolTypes.PositionId(0, 0, 0));
    }

    /**
     * @custom:scenario Tests the {IUsdnLongFarming.ownershipCallback} function with a pending position.
     * @custom:when The function is called.
     * @custom:then The call must revert with {IUsdnLongFarmingErrors.UsdnLongFarmingPendingPosition}.
     */
    function test_RevertWhen_ownershipCallbackPendingPosition() public {
        position.validated = false;
        usdnProtocol.setPosition(position, DEFAULT_TICK_VERSION, false);
        vm.expectRevert(UsdnLongFarmingPendingPosition.selector);
        vm.prank(address(usdnProtocol));
        farming.ownershipCallback(
            address(this), IUsdnProtocolTypes.PositionId(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX)
        );
    }

    /**
     * @custom:scenario Simulates the {IUsdnLongFarming.ownershipCallback} function from the
     * {IUsdnProtocol.transferPositionOwnership} of the USDN protocol.
     * @custom:when The function is called.
     * @custom:then The call must not revert.
     * @custom:and The position must be filled.
     */
    function test_ownershipCallbackFromProtocol() public {
        vm.prank(address(usdnProtocol));
        farming.ownershipCallback(
            address(this), IUsdnProtocolTypes.PositionId(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX)
        );

        PositionInfo memory posInfo = farming.getPositionInfo(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        assertEq(
            keccak256(abi.encode(posInfo)),
            keccak256(
                abi.encode(
                    PositionInfo(
                        address(this),
                        DEFAULT_TICK,
                        DEFAULT_TICK_VERSION,
                        DEFAULT_INDEX,
                        0,
                        position.totalExpo - position.amount
                    )
                )
            ),
            "The position must be filled"
        );
    }
}
