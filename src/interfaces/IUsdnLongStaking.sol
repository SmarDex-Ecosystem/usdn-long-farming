// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IUsdnLongStakingErrors } from "./IUsdnLongStakingErrors.sol";
import { IUsdnLongStakingEvents } from "./IUsdnLongStakingEvents.sol";
import { IUsdnLongStakingTypes } from "./IUsdnLongStakingTypes.sol";

/**
 * @title IUsdnLongStaking
 * @notice Interface for the USDN Long Staking
 */
interface IUsdnLongStaking is IUsdnLongStakingTypes, IUsdnLongStakingErrors, IUsdnLongStakingEvents { }
