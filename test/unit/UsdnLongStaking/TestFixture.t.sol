// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { UsdnLongStakingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature The base fixture of the USDN long staking
 * @custom:background Given a deployed staking contract and USDN protocol
 */
contract TestUsdnLongStakingFixture is UsdnLongStakingBaseFixture {
    function setUp() public {
        _setUp();
    }

    /**
     * @custom:scenario Tests the fixture deployment
     * @custom:when The address of the staking is called
     * @custom:then The address should be a valid address
     */
    function test_fixtures() public view {
        assertTrue(address(staking) != address(0), "The staking address should be deployed");
    }
}
