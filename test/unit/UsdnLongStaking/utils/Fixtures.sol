// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IUsdnLongStakingTypes } from "../../../../src/interfaces/usdnLongStaking/IUsdnLongStakingTypes.sol";
import { IUsdnLongStakingErrors } from "../../../../src/interfaces/usdnLongStaking/IUsdnLongStakingErrors.sol";
import { IUsdnLongStakingEvents } from "../../../../src/interfaces/usdnLongStaking/IUsdnLongStakingEvents.sol";

import { BaseFixture } from "../../../utils/Fixtures.sol";
import { UsdnLongStakingHandler } from "./Handler.sol";

/**
 * @title UsdnLongStakingBaseFixture
 * @dev Utils for testing the USDN Long Staking
 */
contract UsdnLongStakingBaseFixture is
    BaseFixture,
    IUsdnLongStakingTypes,
    IUsdnLongStakingErrors,
    IUsdnLongStakingEvents
{
    UsdnLongStakingHandler internal staking;

    function _setUp() internal virtual {
        staking = new UsdnLongStakingHandler();
    }
}
