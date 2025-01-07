// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { IUsdnLongFarmingTypes } from "../../../src/interfaces/IUsdnLongFarmingTypes.sol";
import { UsdnLongFarmingIntegrationFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the {IUsdnLongFarming._calcRewards} function of the USDN long farming
 * @custom:background Given a deployed farming contract and USDN protocol
 */
contract TestUsdnLongFarmingCalcRewards is UsdnLongFarmingIntegrationFixture {
    function setUp() public {
        _setUp();
    }

    function test_test() public pure {
        assertTrue(true, "FALSE");
    }
}
