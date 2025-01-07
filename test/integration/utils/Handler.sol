// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { IUsdnProtocol } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocol.sol";

import { UsdnLongFarming } from "../../../../src/UsdnLongFarming.sol";
import { IFarmingRange } from "../../../../src/interfaces/IFarmingRange.sol";

/**
 * @title UsdnLongFarmingHandler
 * @dev Utils for testing the USDN Long Farming
 */
contract UsdnLongFarmingHandler is UsdnLongFarming {
    constructor(IUsdnProtocol usdnProtocol, IFarmingRange rewardsProvider, uint256 farmingCampaignId)
        UsdnLongFarming(IUsdnProtocol(address(usdnProtocol)), rewardsProvider, farmingCampaignId)
    { }
}
