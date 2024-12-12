// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import { ERC20 } from "solady-0.0/tokens/ERC20.sol";

import { IUsdnLongStaking } from "./interfaces/IUsdnLongStaking.sol";
import { IFarmingRange } from "./interfaces/IFarmingRange.sol";

/**
 * @title UsdnLongStaking
 * @notice Contract for the USDN Long Staking
 */
contract UsdnLongStaking is IUsdnLongStaking, ERC20 {
    string internal constant _NAME = "Staked USDN Long";
    string internal constant _SYMBOL = "stUL";

    IFarmingRange public immutable FARMING;
    uint256 public immutable CAMPAIGN_ID;
    ERC20 public immutable REWARD_TOKEN;

    constructor(IFarmingRange farming, uint256 campaignId) {
        FARMING = farming;
        CAMPAIGN_ID = campaignId;
        REWARD_TOKEN = ERC20(address(farming.campaignInfo(campaignId).rewardToken));
    }

    function name() public pure override returns (string memory name_) {
        return _NAME;
    }

    function symbol() public pure override returns (string memory symbol_) {
        return _SYMBOL;
    }
}
