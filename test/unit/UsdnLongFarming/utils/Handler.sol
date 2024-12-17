// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IUsdnProtocol } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocol.sol";
import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";

import { MockFarmingRange } from "./MockFarmingRange.sol";
import { MockUsdnProtocol } from "./MockUsdnProtocol.sol";

import { UsdnLongFarming } from "../../../../src/UsdnLongFarming.sol";
import { IFarmingRange } from "../../../../src/interfaces/IFarmingRange.sol";

/**
 * @title UsdnLongFarmingHandler
 * @dev Utils for testing the USDN Long Farming
 */
contract UsdnLongFarmingHandler is UsdnLongFarming {
    constructor(MockUsdnProtocol usdnProtocol, MockFarmingRange farming)
        UsdnLongFarming(IUsdnProtocol(address(usdnProtocol)), IFarmingRange(address(farming)), 0)
    { }

    function i_updateRewards() external {
        _updateRewards();
    }

    function i_checkPosition(IUsdnProtocolTypes.Position calldata position) external view {
        _checkPosition(position);
    }

    function setTotalShares(uint256 totalShares) external {
        _totalShares = totalShares;
    }
}
