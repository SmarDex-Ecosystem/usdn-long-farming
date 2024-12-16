// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import { IERC20 } from "@openzeppelin-contracts-5/token/ERC20/IERC20.sol";
import { IUsdnProtocol } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocol.sol";
import { IUsdnProtocolTypes } from "@smardex-usdn-contracts/interfaces/UsdnProtocol/IUsdnProtocolTypes.sol";

import { IFarmingRange } from "./interfaces/IFarmingRange.sol";
import { IUsdnLongStaking } from "./interfaces/IUsdnLongStaking.sol";

/**
 * @title USDN Long Positions Staking
 * @notice A contract for staking USDN long positions to earn rewards.
 */
contract UsdnLongStaking is IUsdnLongStaking {
    /// @dev Scaling factor for `_accRewardPerShare`.
    uint256 public constant SCALING_FACTOR = 1e20;

    /// @notice The address of the USDN protocol contract.
    IUsdnProtocol public immutable USDN_PROTOCOL;

    /// @notice The address of the SmarDex `FarmingRange` contract, which is the source of the reward tokens.
    IFarmingRange public immutable FARMING;

    /// @notice The ID of the campaign in the `FarmingRange` contract which provides reward tokens to this contract.
    uint256 public immutable CAMPAIGN_ID;

    /// @notice The address of the reward token.
    IERC20 public immutable REWARD_TOKEN;

    /// @dev The position information for each locked position, identified by the hash of its `PositionId`.
    mapping(bytes32 => PositionInfo) internal _positions;

    /// @dev The total number of locked positions.
    uint256 internal _positionsCount;

    /// @dev The sum of all locked positions' initial trading exposure.
    uint256 internal _totalShares;

    /// @dev Accumulated reward tokens per share multiplied by `SCALING_FACTOR`.
    uint256 internal _accRewardPerShare;

    /// @dev Block number when the last rewards were calculated.
    uint256 internal _lastRewardBlock;

    /**
     * @param usdnProtocol The USDN protocol contract used to transfer the user long position ownership.
     * @param farming The Smardex farming contract.
     * @param campaignId The campaign id of the Smardex farming that will give rewards.
     */
    constructor(IUsdnProtocol usdnProtocol, IFarmingRange farming, uint256 campaignId) {
        USDN_PROTOCOL = usdnProtocol;
        FARMING = farming;
        IFarmingRange.CampaignInfo memory info = farming.campaignInfo(campaignId);
        REWARD_TOKEN = IERC20(address(info.rewardToken));
        IERC20 farmingToken = IERC20(address(info.stakingToken));
        // this contract is the sole depositor of the farming token in the farming contract, and will receive all of the
        // rewards
        farmingToken.transferFrom(msg.sender, address(this), 1);
        farmingToken.approve(address(farming), 1);
        farming.deposit(campaignId, 1);
    }

    /// @inheritdoc IUsdnLongStaking
    function getPositionInfo(bytes32 posHash) external view returns (PositionInfo memory posInfo_) {
        return _positions[posHash];
    }

    /// @inheritdoc IUsdnLongStaking
    function getPositionsCount() external view returns (uint256 positionsCount_) {
        return _positionsCount;
    }

    /// @inheritdoc IUsdnLongStaking
    function getTotalShares() external view returns (uint256 totalShares_) {
        return _totalShares;
    }

    /// @inheritdoc IUsdnLongStaking
    function getAccRewardPerShare() external view returns (uint256 accRewardPerShare_) {
        return _accRewardPerShare;
    }

    /// @inheritdoc IUsdnLongStaking
    function getLastRewardBlock() external view returns (uint256 lastRewardBlock_) {
        return _lastRewardBlock;
    }

    /// @inheritdoc IUsdnLongStaking
    function getPosIdHash(int24 tick, uint256 tickVersion, uint256 index) external pure returns (bytes32 hash_) {
        return _hashPositionId(tick, tickVersion, index);
    }

    /// @inheritdoc IUsdnLongStaking
    function deposit(int24 tick, uint256 tickVersion, uint256 index, bytes calldata delegation)
        external
        returns (bool success_)
    {
        IUsdnProtocolTypes.Position memory pos = USDN_PROTOCOL.getCurrentLongPosition(tick, index);

        _checkPosition(pos);
        _updateRewards();

        uint128 currentTradingExpo = pos.totalExpo - pos.amount;
        PositionInfo memory posInfo = PositionInfo({
            owner: pos.user,
            tick: tick,
            tickVersion: tickVersion,
            index: index,
            rewardDebt: currentTradingExpo * _accRewardPerShare / SCALING_FACTOR,
            shares: currentTradingExpo
        });

        _totalShares += posInfo.shares;
        _positionsCount++;
        bytes32 positionIdHash = _hashPositionId(tick, tickVersion, index);
        _positions[positionIdHash] = posInfo;

        USDN_PROTOCOL.transferPositionOwnership(
            IUsdnProtocolTypes.PositionId(tick, tickVersion, index), address(this), delegation
        );

        emit UsdnLongStakingDeposit(posInfo.owner, positionIdHash);
        return true;
    }

    /**
     * @notice Hash a USDN long position's ID to use a key in the `_positions` mapping.
     * @param tick The tick of the position.
     * @param tickVersion The version of the tick.
     * @param index The index of the position inside the tick.
     * @return hash_ The hash of the position ID.
     */
    function _hashPositionId(int24 tick, uint256 tickVersion, uint256 index) internal pure returns (bytes32 hash_) {
        hash_ = keccak256(abi.encode(tick, tickVersion, index));
    }

    /**
     * @notice Harvests pending rewards from `_lastRewards`, updates `_accRewardPerShare` and `_lastRewardBlock`.
     * @dev If there is no shares deposited, `lastRewardBlock` will be updated but harvest will not be triggered for
     * this period of blocks.
     */
    function _updateRewards() internal {
        if (_lastRewardBlock < block.number) {
            if (_totalShares == 0) {
                _lastRewardBlock = block.number;
                return;
            }

            uint256 rewardsBalanceBefore = REWARD_TOKEN.balanceOf(address(this));

            // farming harvest
            uint256[] memory campaignsIds = new uint256[](1);
            campaignsIds[0] = CAMPAIGN_ID;
            FARMING.harvest(campaignsIds);

            // rewardPerBlock = token amount harvested / amount of blocks from the `_lastRewardBlock`
            uint256 rewardsPerBlock =
                (REWARD_TOKEN.balanceOf(address(this)) - rewardsBalanceBefore) / (block.number - _lastRewardBlock);

            if (rewardsPerBlock > 0) {
                _accRewardPerShare += rewardsPerBlock * SCALING_FACTOR / _totalShares;
            }

            _lastRewardBlock = block.number;
        }
    }

    /**
     * @notice Checks that the user USDN protocol position is currently valid.
     * @param position The user USDN protocol position on which the checks must be performed.
     */
    function _checkPosition(IUsdnProtocolTypes.Position memory position) internal view {
        if (position.user == address(this)) {
            revert UsdnLongStakingContractOwned();
        }

        if (!position.validated) {
            revert UsdnLongStakingPendingPosition();
        }

        if (position.totalExpo <= position.amount) {
            revert UsdnLongStakingInvalidTradingExpo();
        }
    }
}
