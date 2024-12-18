// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { UsdnLongFarmingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature The base fixture of the USDN long farming
 * @custom:background Given a deployed farming contract and USDN protocol
 */
contract TestUsdnLongFarmingFixture is UsdnLongFarmingBaseFixture {
    function setUp() public {
        _setUp();
    }

    /**
     * @custom:scenario Tests the fixture deployment
     * @custom:when The address of the farming is called
     * @custom:then The address should be a valid address
     */
    function test_fixtures() public view {
        assertTrue(address(farming) != address(0), "The farming address should be deployed");
    }
}
