// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";

import { UsdnLongFarmingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the {IUsdnLongFarming._isLiquidated} function of the USDN long farming
 * @custom:background Given a deployed farming contract and USDN protocol
 */
contract TestUsdnLongFarmingIsLiquidated is UsdnLongFarmingBaseFixture {
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
        posHash = farming.i_hashPositionId(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX);
        usdnProtocol.transferPositionOwnership(
            IUsdnProtocolTypes.PositionId(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX), address(farming), ""
        );
    }

    /**
     * @custom:scenario Tests {IUsdnLongFarming._isLiquidated} with a not liquidated position.
     * @custom:given The farming contract with a not liquidated position in the USDN protocol.
     * @custom:when The function is called with the default tick and tick version.
     * @custom:then Returns false.
     */
    function test_isLiquidatedNotLiquidated() public view {
        assertFalse(farming.i_isLiquidated(DEFAULT_TICK, DEFAULT_TICK_VERSION), "The position must not be liquidated");
    }

    /**
     * @custom:scenario Tests {IUsdnLongFarming._isLiquidated} with a liquidated position.
     * @custom:given The farming contract with a liquidated position in the USDN protocol.
     * @custom:when The function is called with the default tick and tick version.
     * @custom:then Returns true.
     */
    function test_isLiquidatedLiquidated() public {
        usdnProtocol.setPosition(position, DEFAULT_TICK_VERSION, true);
        assertTrue(farming.i_isLiquidated(DEFAULT_TICK, DEFAULT_TICK_VERSION), "The position must be liquidated");
    }
}
