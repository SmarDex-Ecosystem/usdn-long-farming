// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IUsdnLongFarmingErrors } from "./IUsdnLongFarmingErrors.sol";
import { IUsdnLongFarmingEvents } from "./IUsdnLongFarmingEvents.sol";
import { IUsdnLongFarmingTypes } from "./IUsdnLongFarmingTypes.sol";

/**
 * @title IUsdnLongFarming
 * @notice Interface for the USDN Long Farming.
 */
interface IUsdnLongFarming is IUsdnLongFarmingTypes, IUsdnLongFarmingErrors, IUsdnLongFarmingEvents { }
