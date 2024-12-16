// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { UsdnLongStakingBaseFixture } from "./utils/Fixtures.sol";

/**
 * @custom:feature Tests the {deposit} of the USDN long staking
 * @custom:background Given a deployed staking contract and USDN protocol
 */
contract TestUsdnLongStakingDeposit is UsdnLongStakingBaseFixture {
    function setUp() public {
        _setUp();
    }

    /**
     * @custom:scenario Tests the deposit
     * @custom:when
     * @custom:then
     */
    function test_deposit() public view { }
}
