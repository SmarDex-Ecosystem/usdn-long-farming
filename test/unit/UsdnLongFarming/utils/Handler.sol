// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { IUsdnProtocol } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocol.sol";

import { MockRewardsProvider } from "./MockRewardsProvider.sol";
import { MockUsdnProtocol } from "./MockUsdnProtocol.sol";

import { UsdnLongFarming } from "../../../../src/UsdnLongFarming.sol";
import { IFarmingRange } from "../../../../src/interfaces/IFarmingRange.sol";

/**
 * @title UsdnLongFarmingHandler
 * @dev Utils for testing the USDN Long Farming
 */
contract UsdnLongFarmingHandler is UsdnLongFarming {
    constructor(MockUsdnProtocol usdnProtocol, MockRewardsProvider rewardsProvider)
        UsdnLongFarming(IUsdnProtocol(address(usdnProtocol)), IFarmingRange(address(rewardsProvider)), 0)
    { }

    function i_updateRewards() external {
        _updateRewards();
    }

    function i_slash(
        bytes32 positionIdHash,
        uint256 rewards,
        address notifier,
        int24 tick,
        uint256 tickVersion,
        uint256 index
    ) external {
        _slash(positionIdHash, rewards, notifier, tick, tickVersion, index);
    }

    function i_isLiquidated(int24 tick, uint256 tickVersion) external view returns (bool) {
        return _isLiquidated(tick, tickVersion);
    }

    function i_harvest(bytes32 positionIdHash)
        external
        returns (bool isLiquidated_, uint256 rewards_, uint256 newRewardDebt_, address owner_)
    {
        return _harvest(positionIdHash);
    }

    function i_calcRewards(PositionInfo memory posInfo, uint256 accRewardPerShare)
        external
        pure
        returns (uint256 rewards_, uint256 newRewardDebt_)
    {
        return _calcRewards(posInfo, accRewardPerShare);
    }

    function i_sendRewards(address to, uint256 amount, int24 tick, uint256 tickVersion, uint256 index) external {
        _sendRewards(to, amount, tick, tickVersion, index);
    }

    function i_deletePosition(bytes32 positionIdHash) external {
        _deletePosition(positionIdHash);
    }

    function setTotalShares(uint256 totalShares) external {
        _totalShares = totalShares;
    }

    function set_accRewardPerShare(uint256 accRewardPerShare) external {
        _accRewardPerShare = accRewardPerShare;
    }
}
