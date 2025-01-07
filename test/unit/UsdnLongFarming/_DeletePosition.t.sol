// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";

import { UsdnLongFarmingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the {IUsdnLongFarming._deletePosition} function of the USDN long farming
 * @custom:background Given a deployed farming contract and USDN protocol
 */
contract TestUsdnLongFarmingDeletePosition is UsdnLongFarmingBaseFixture {
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
     * @custom:scenario Tests the delete position with a deposited position.
     * @custom:when The function {IUsdnLongFarming._deletePosition} is called.
     * @custom:then The position is deleted.
     * @custom:and The global state is updated.
     */
    function test_deletePosition() public {
        uint256 totalSharesBefore = farming.getTotalShares();
        uint256 positionsCountBefore = farming.getPositionsCount();

        farming.i_deletePosition(posHash);
        assertEq(farming.getPositionsCount(), positionsCountBefore - 1, "The position is deleted");
        assertEq(farming.getTotalShares(), totalSharesBefore - 10, "The shares are updated");
        assertEq(
            keccak256(abi.encode(farming.getPositionInfo(DEFAULT_TICK, DEFAULT_TICK_VERSION, DEFAULT_INDEX))),
            keccak256(abi.encode(PositionInfo(address(0), 0, 0, 0, 0, 0))),
            "The position info is deleted"
        );
    }
}
