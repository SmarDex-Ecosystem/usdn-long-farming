// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import { ERC20 } from "solady-0.0/tokens/ERC20.sol";

import { IFarmingRange } from "./interfaces/IFarmingRange.sol";
import { IUsdnLongStaking } from "./interfaces/IUsdnLongStaking.sol";

/**
 * @title USDN Long Positions Staking
 * @notice A contract for staking USDN long positions to earn rewards.
 */
contract UsdnLongStaking is IUsdnLongStaking, ERC20 {
    /// @dev The name of the token used in the farming campaign
    string internal constant NAME = "Staked USDN Long";
    string internal constant SYMBOL = "stUL";

    /**
     * @notice The address of the SmarDex `FarmingRange` contract, which is the source of the reward tokens.
     */
    IFarmingRange public immutable FARMING;
    uint256 public immutable CAMPAIGN_ID;
    ERC20 public immutable REWARD_TOKEN;

    /// @dev The position information for each locked position, identified by the hash of its `PositionId`.
    mapping(bytes32 => PositionInfo) internal _positions;

    /// @dev The total number of locked positions.
    uint256 internal _positionsCount;

    /// @dev The sum of all locked positions' trading exposure.
    uint256 internal _totalShares;

    constructor(IFarmingRange farming, uint256 campaignId) {
        FARMING = farming;
        CAMPAIGN_ID = campaignId;
        IFarmingRange.CampaignInfo memory info = farming.campaignInfo(campaignId);
        REWARD_TOKEN = ERC20(address(info.rewardToken));
        ERC20 farmingToken = ERC20(address(info.stakingToken));
        farmingToken.transferFrom(msg.sender, address(this), 1);
        farmingToken.approve(address(farming), 1);
        farming.deposit(campaignId, 1, address(this));
    }

    function name() public pure override returns (string memory name_) {
        return NAME;
    }

    function symbol() public pure override returns (string memory symbol_) {
        return SYMBOL;
    }
}
